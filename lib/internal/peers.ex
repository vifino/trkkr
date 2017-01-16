# Internal Peer API
# Registering peers and such.

defmodule Trkkr.Internal.Peers do
  @moduledoc """
  Internal module for keeping track of peers.
  Stores the peers as a set in the memory store
  with the 20 byte SHA1 hash of the bencoded info
  dictionary as the key. not many alternatives
  to that, really.
  """

  alias Trkkr.Storage.Memory

  # Helpers
  defp peerinfo2list(peer) do
    [peer["ip"], peer["port"], peer["uploaded"], peer["downloaded"], peer["left"], peer["key"]]
  end
  defp list2peerinfo(list) do
    [ip, port, uploaded, downloaded, left, key] = list
    %{
      "ip" => ip,
      "port" => port,
      "uploaded" => uploaded,
      "downloaded" => downloaded,
      "left" => left,
      "key" => key
    }
  end
  defp knowntorrent?(info_hash) do # Ugly.
    Memory.exists?("peers_incomplete_" <> info_hash) and Memory.exists?("peers_completed_" <> info_hash)
  end

  # Peer data
  defp peer_set(info_hash, peerinfo) do
    Memory.set_store("peer_" <> info_hash <> "_" <> peerinfo["peer_id"], peerinfo2list(peerinfo))
  end
  defp peer_get(info_hash, peerid) do
    Memory.set_fetch("peer_" <> info_hash <> "_" <> peerid)
    |> list2peerinfo()
  end
  defp peer_del(info_hash, peerid) do
    Memory.set_delete("peer_" <> info_hash <> "_" <> peerid)
  end

  # Peer book keeping
  # Keeps a list of peers for a torrent.
  def handle_newtorrent(info_hash) do
    if !knowntorrent? info_hash do
      IO.puts "First update? Setting peers store."
      Memory.set_store("peers_completed_" <> info_hash, [])
      Memory.set_store("peers_incomplete_" <> info_hash, [])
    end
  end
  def updatepeer(info_hash, peerinfo) do
    IO.puts "Peers.updatepeer"
    handle_newtorrent info_hash
    if peerinfo["event"] == "stopped" do
      delpeer(info_hash, peerinfo["peer_id"])
    else
      peer_set(info_hash, peerinfo)
      if peerinfo["left"] == 0 do
        Memory.set_remove("peers_incomplete_" <> info_hash, peerinfo["peer_id"])
        Memory.set_add("peers_completed_" <> info_hash, peerinfo["peer_id"])
        if peerinfo["event"] == "completed" do
          Memory.add("completed_" <> info_hash, 1)
        end
      else
        Memory.set_add("peers_incomplete_" <> info_hash, peerinfo["peer_id"])
      end
    end
  end
  def delpeer(info_hash, peerid) do
    IO.puts "Peers.delpeer"
    if Memory.set_length?("peers_completed_" <> info_hash) > 0 do
      Memory.set_remove("peers_completed_" <> info_hash, peerid)
    end
    if Memory.set_length?("peers_incomplete_" <> info_hash) > 0 do
      Memory.set_remove("peers_incomplete_" <> info_hash, peerid)
    end
    peer_del(info_hash, peerid)
  end
  def delpeers(info_hash) do
    Memory.set_fetch("peers_completed_" <> info_hash)
    |> Trkkr.Helpers.pmap(fn peerid -> delpeer(info_hash, peerid) end)
    Memory.set_fetch("peers_completed_" <> info_hash)
    |> Trkkr.Helpers.pmap(fn peerid -> delpeer(info_hash, peerid) end)
    Memory.set_delete("peers_completed_" <> info_hash)
    Memory.set_delete("peers_incomplete_" <> info_hash)
  end

  # Peer getting/selection
  def getpeers_complete(info_hash) do
    Memory.set_fetch("peers_completed_" <> info_hash)
    |> Trkkr.Helpers.pmap(fn peerid -> peer_get(info_hash, peerid) end)
  end
  def getpeers_incomplete(info_hash) do
    Memory.set_fetch("peers_incomplete_" <> info_hash)
    |> Trkkr.Helpers.pmap(fn peerid -> peer_get(info_hash, peerid) end)
  end

  @doc """
  'Smart' peer selection for leechers.
  In theory, this should give leechers
  the best chance of finishing their download.
  First, it gets up to max_peers seeders,
  randomly selected from the pool.
  If there are less than max_peers seeders,
  it fills the rest up with random leechers.
  """
  def getpeers_smart_leechers(info_hash, own_peerid, max_peers) do
    completed = Memory.set_fetch("peers_completed_" <> info_hash)
                |> Enum.take_random(max_peers)
                |> Trkkr.Helpers.pmap(fn peerid -> peer_get(info_hash, peerid) end)
    if length(completed) < max_peers do
      incomplete = Memory.set_fetch("peers_incomplete_" <> info_hash)
                   |> Enum.filter(fn peerid -> peerid != own_peerid end)
                   |> Enum.take_random(max_peers - length(completed))
                   |> Trkkr.Helpers.pmap(fn peerid -> peer_get(info_hash, peerid) end)
      completed ++ incomplete
    else
      completed
    end
  end

  def getpeers_smart(peer) do
    if peer["left"] == 0 do # complete
      Memory.set_fetch("peers_incomplete_" <> peer["info_hash"])
      |> Enum.take_random(peer["numwant"])
      |> Trkkr.Helpers.pmap(fn peerid -> peer_get(peer["info_hash"], peerid) end)
    else
      getpeers_smart_leechers(peer["info_hash"], peer["peer_id"], peer["numwant"])
    end
  end

  def seeders?(info_hash) do
    len = Memory.set_length?("peers_completed_" <> info_hash)
    if len == nil do
      0
    else
      len
    end
  end
  def leechers?(info_hash) do
    len = Memory.set_length?("peers_incomplete_" <> info_hash)
    if len == nil do
      0
    else
      len
    end
  end
 end
