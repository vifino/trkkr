# Redis backend for the storage API

# Dear me. When you look at this, something
# probably broke horribly, like it should've
# since the start. How about you clean this
# shit up? Seriously.
# Yes, I know it worked and it most likely
# will again, but it is just /bad/ code.
# Thanks.
#
# PS: Replace this code already or I swear
# you will see this text again.

defmodule Trkkr.Storage.Redis do
  @moduledoc """
  A storage backend for metadata using Redis.
  """

  import Exredis.Api

  def start_link do
    {:ok, client} = Exredis.start_link
    true = Process.register(client, :trkkr_redis)
    {:ok, client}
  end

  # Helpers
  defp getclient do
    Process.whereis(:trkkr_redis)
  end
  defp escape_pattern(str) do
    to_charlist(str)
    |> Enum.reduce([], fn char, res -> res ++ '\\' ++ [char] end)
    |> to_string()
  end

  # Storing operations
  def store(key, value) do
    getclient() |> set("trkkr_" <> key, value)
  end
  def set_store(key, values) do
    nkey = "trkkr_" <> key
    client = getclient()
    client |> del(nkey)
    client |> sadd(nkey, values)
  end
  def set_add(key, values) do
    getclient() |> sadd("trkkr_" <> key, values)
  end

  # Fetching operations
  def fetch(key) do
    getclient() |> get("trkkr_" <> key)
  end
  def set_fetch(key) do
    getclient() |> smembers("trkkr_" <> key)
  end

  # Delete operations
  def delete(key) do
    getclient() |> del("trkkr_" <> key)
  end
  def set_remove(key, value) do
    getclient() |> srem("trkkr_" <> key, value)
  end
  def set_delete(key) do
    delete(key)
  end

  # Listing/finding operations
  def list() do
    # I don't wanna talk about it.
    find("")
  end
  def find(beginning \\ "") do
    # Probably very bad to do it this way, but whatever.
    getclient()
    |> keys("trkkr_" <> escape_pattern(beginning) <> "*")
  end

  # Checking functions
  def exists?(key) do
    case exists(getclient(), "trkkr_" <> key) do
      1 -> true
      0 -> false
    end
  end
end
