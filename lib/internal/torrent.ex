# Module for keeping track of torrents.
# Yay.

require IEx

defmodule Trkkr.Internal.Torrent do
  @moduledoc """
  This module keeps track of torrents.
  It sets the required things for the
  tracker to keep track of torrents.
  In combination with the peer module
  it should allow Trkkr to keep track
  of everything required to make stuff
  function.
  """
  
  # Helper-esque things.
  def gen_info_hash!(info) do
    :crypto.hash(:sha, Bento.encode!(info))
  end
  defp store_torrent!(info_hash, metadata) do
    Trkkr.Storage.Redis.store("md_" <> info_hash, Bento.encode!(metadata))
    :ok
  end

  # More public interface.
  def new_torrent!(metadata, name) do
    gen_info_hash!(metadata.info)
    |> new_torrent!(metadata, name)
  end
  def new_torrent!(info_hash, metadata, name) do
    IEx.pry
    Trkkr.Storage.Redis.store("title_" <> info_hash, name)
    store_torrent!(info_hash, metadata)
    Trkkr.Internal.Peers.handle_newtorrent(info_hash)
    {:ok, info_hash}
  end
  
  def get_torrent!(info_hash) do
    metadata = Trkkr.Storage.Redis.fetch("md_" <> info_hash)
               |> Bento.decode!
    title = Trkkr.Storage.Redis.fetch("title_" <> info_hash)
    {title, metadata}
  end
  
  def del_torrent!(info_hash) do
    # Now, we have to do a bit more cleanup.
    Trkkr.Storage.Redis.delete("md_" <> info_hash)
    Trkkr.Storage.Redis.delete("title_" <> info_hash)
    Trkkr.Internal.Peers.delpeers(info_hash)
  end

  def list_torrents!() do
    Trkkr.Storage.Redis.find("md_")
    |> Trkkr.Helpers.pmap(fn str -> String.trim_leading(str, "md_") end)
  end

  def exists?(info_hash) do
    Trkkr.Storage.Redis.exists?("md_" <> info_hash)
  end
end
