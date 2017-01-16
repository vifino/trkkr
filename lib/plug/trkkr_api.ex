# Main, public facing API calling the internal API.
# Hopefully, it works too!

defmodule Trkkr.Plug.TrkkrAPI do
  @moduledoc """
  This module provides two API endpoints, /announce and /scrape.
  """

  # /announce and such error messages.
  def gen_failmsg(msg), do: Bento.encode! %{"failure reason" => msg}

  def init(_opts) do
    %{
      err_invalid_request: gen_failmsg("The request is invalid and lacks one or more options."),
      err_unknown_torrent: gen_failmsg("Torrent not known to this Tracker."),
      err_scrape_unknown_torrent: Bento.encode! %{"files" => %{},
                                                  "failure reason" => "Torrent not known to this Tracker."}
    }
  end

  # "Generic" Helpers
  defp common(conn) do
    conn
    |> Plug.Conn.fetch_query_params
  end

  # /scrape helpers
  defp scrape_pack_info(info_hash) do
    %{
		  "name" => Trkkr.Internal.Torrent.name?(info_hash),
		  "complete" => Trkkr.Internal.Peers.seeders?(info_hash),
		  "incomplete" => Trkkr.Internal.Peers.leechers?(info_hash),
		  "downloaded" => Trkkr.Internal.Torrent.completed?(info_hash)
		}
  end

  @doc """
  The handler for adding a torrent.
  Since we are in a "whitelist" mode, we
  need to add the torrent to get the metadata,
  info_hash and such.

  tl;dr curl -F"name=mytorrent" -F"torrent=@/path/to/mytorrent.torrent" server:port/new_torrent
  """
  def call(%Plug.Conn{request_path: "/new_torrent", method: "POST"} = conn, _opts) do
    IO.puts "/new_torrent omg"
    conn = common(conn) |> Plug.Conn.put_resp_content_type("text/plain")
    if conn.params["torrent"] == nil do
      Plug.Conn.send_resp(conn, 400, "Uhm, you need to provide the torrent data too, ya know?")
      |> Plug.Conn.halt
    else
      torrent_checker = cond do
        %Plug.Upload{filename: name, path: path} = conn.params["torrent"] ->
          if is_binary(conn.params["name"]) do
            {:ok, conn.params["name"], File.read! path}
          else
            {:ok, name, File.read! path}
          end
        is_binary(conn.params["torrent"]) ->
          if is_binary conn.params["name"] == false do
            {:error, "Your torrent needs a name, too."}
          else
            {:ok, conn.params["name"], conn.params["torrent"]}
          end
      end
      cond do
        elem(torrent_checker, 0) == :error ->
          Plug.Conn.send_resp(conn, 400, elem(torrent_checker, 1)) |> Plug.Conn.halt
        elem(torrent_checker, 0) == :ok ->
          {:ok, name, torrent_data} = torrent_checker
          {success, metadata} = Bento.decode(torrent_data)
          if success == :ok do
            {retstatus, returnval} = Trkkr.Internal.API.new_torrent(metadata, name)
            case retstatus do
              :ok -> Plug.Conn.send_resp(conn, 200, Base.encode16(returnval)) |> Plug.Conn.halt
              :error -> Plug.Conn.send_resp(conn, 400, returnval) |> Plug.Conn.halt
            end
          else
            Plug.Conn.send_resp(conn, 400, "Couldn't decode torrent. You sure it's correct?")
            |> Plug.Conn.halt
          end
      end
    end
  end

  @doc """
  The announce request handler.
  """
  def call(%Plug.Conn{request_path: "/announce", method: "GET"} = conn, opts) do
    IO.puts "Oh shit, an /announce"
    conn = common(conn) |> Plug.Conn.put_resp_content_type("text/plain")
    params = Trkkr.Parser.Announce.parse!(conn.query_params)
    valid = cond do
      params["info_hash"] == nil -> false
      params["peer_id"] == nil -> false
      params["port"] == nil -> false
      params["uploaded"] == nil -> false
      params["downloaded"] == nil -> false
      params["left"] == nil -> false
      true -> true # wew.
    end
    if valid do
      new_params = cond do
        params["ip"] == nil -> Map.put(params, "ip", conn.remote_ip |> Tuple.to_list |> Enum.join("."))
        true -> params
      end
      peer_resp = Trkkr.Internal.API.peer_update(new_params)
      if peer_resp != nil do
        conn
        |> Plug.Conn.send_resp(200, Bento.encode! peer_resp)
        |> Plug.Conn.halt
      else
        conn
        |> Plug.Conn.send_resp(200, opts.err_unknown_torrent)
        |> Plug.Conn.halt
      end
    else
      conn
      |> Plug.Conn.send_resp(400, opts.err_invalid_request)
      |> Plug.Conn.halt
    end
  end

  @doc """
  The scrape request handler.
  Following the "scrape page convention",
  documented here: https://groups.yahoo.com/neo/groups/BitTorrent/conversations/topics/3275
  """
  def call(%Plug.Conn{request_path: "/scrape", method: "GET"} = conn, opts) do
    # TODO: Make less stub.
    IO.puts "These fuckers are /scrape-ing!"
    conn = common(conn) |> Plug.Conn.put_resp_content_type("text/plain")
    params = conn.query_params
    if params["info_hash"] != nil do # only wants info for a single torrent
      info_hash = params["info_hash"]
      if !Trkkr.Internal.Torrent.exists? info_hash do
        # invalid torrent, send them an error message.
        conn
        |> Plug.Conn.send_resp(200, opts.err_scrape_unknown_torrent)
				|> Plug.Conn.halt
      else
		    conn
		    |> Plug.Conn.send_resp(200, Bento.encode! %{
          "files" => %{info_hash => scrape_pack_info(info_hash)}
        })
        |> Plug.Conn.halt
      end
    else # wants *all* the torrent infos. greedy bastard.
      files = Trkkr.Internal.Torrent.list_torrents!
              |> Enum.reduce(%{}, fn(info_hash, acc) -> 
                Map.put(acc, info_hash, scrape_pack_info(info_hash))
              end)
      conn
      |> Plug.Conn.send_resp(200, Bento.encode! %{"files" => files})
      |> Plug.Conn.halt
    end
  end

  # Default
  def call(conn, _)do
    conn
  end
end
