# Module for keeping track of torrents.
# Yay.

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

  alias Trkkr.Storage.Redis
  alias Trkkr.Internal.Peers

  # Helper-esque things.
  def gen_info_hash!(info) do
    :crypto.hash(:sha, Bento.encode!(info))
  end
  defp store_torrent!(info_hash, metadata) do
    Redis.store("md_" <> info_hash, Bento.encode!(metadata))
    :ok
  end

  # More public interface.
  def new_torrent!(metadata, name) do
    gen_info_hash!(metadata["info"])
    |> new_torrent!(metadata, name)
  end
  def new_torrent!(info_hash, metadata, name) do
    Redis.store("title_" <> info_hash, name)
    store_torrent!(info_hash, metadata)
    Peers.handle_newtorrent(info_hash)
    {:ok, info_hash}
  end

  def get_torrent!(info_hash) do
    metadata = Redis.fetch("md_" <> info_hash)
               |> Bento.decode!
    title = Redis.fetch("title_" <> info_hash)
    {title, metadata}
  end

  def del_torrent!(info_hash) do
    # Now, we have to do a bit more cleanup.
    Redis.delete("md_" <> info_hash)
    Redis.delete("title_" <> info_hash)
    Peers.delpeers(info_hash)
  end

  def add_completed(info_hash) do
    Redis.add("completed_" <> info_hash)
  end

  # "Question" section
  def list_torrents!() do
    Redis.find("md_")
    |> Trkkr.Helpers.pmap(fn str -> String.trim_leading(str, "md_") end)
  end

  def exists?(info_hash) do
    Redis.exists?("md_" <> info_hash)
  end

  def name?(info_hash) do
    Redis.fetch("title_" <> info_hash)
  end

  def completed?(info_hash) do
    completed = Redis.fetch("completed_" <> info_hash)
    if completed != nil do
      completed
    else
      0
    end
  end
end
