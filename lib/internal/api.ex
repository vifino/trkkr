# Internal API glue
# pls no

defmodule Trkkr.Internal.API do
  use GenServer
  @moduledoc """
  This is supposed to combine all the internal APIs and
  make it rather simple to access the data stored.
  However, it is rather likely that it isn't as general
  as it should be. That is just the way things are.
  """

  @doc "Starts the API glue thing."
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :trkkr_api)
  end


  @doc "Adds a torrent, making it available for tracker-use."
  def new_torrent(metadata, name) do
    if metadata["info"] == nil do
      {:error, "metadata info is nil. not good."}
    else
      hash = Trkkr.Internal.Torrent.gen_info_hash!(metadata["info"])
      cond do
        Trkkr.Internal.Torrent.exists?(hash) ->
          # Already exists.
          {:error, "A Torrent with that hash already exists."}
        true ->
          Trkkr.Internal.Torrent.new_torrent!(hash, metadata, name)
      end
    end
  end

  @peer_update_map_template %{
    "interval" => 300,
    "min interval" => 30,
  }

  @doc "Handles peer updates, aka requests to /announce."
  def peer_update(params) do
    IO.puts "API.peer_update"
    if Trkkr.Internal.Torrent.exists? params["info_hash"] do
      # Okay, we got a valid update for a torrent which we track, too.
      # Now we need to handle the shit out of that request. Halleluja.

      # First, keep track of that peer and it's status.
      Trkkr.Internal.Peers.updatepeer(params["info_hash"], params)
      # Second, generate a response! Yaaay.
      # So, we'll generate a map with all the stuff required,
      # the callee will most likely bencode it and send it to
      # the client, where it belongs.
      peers = Trkkr.Internal.Peers.getpeers_smart(params)
              |> Trkkr.Helpers.pmap(fn peer -> %{"peer id" => peer["peer_id"],
                                                 "ip" => peer["ip"], "port" => peer["port"]} end)

      @peer_update_map_template
      |> Map.put("complete", Trkkr.Internal.Peers.seeders? params["info_hash"])
      |> Map.put("incomplete", Trkkr.Internal.Peers.leechers? params["info_hash"])
      |> Map.put("peers", peers)
    end
  end
end
