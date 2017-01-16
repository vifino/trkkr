# Agent-based Key-Value store.

defmodule Trkkr.Storage.Memory do
  @moduledoc """
  Simple Agent-based memory-only Key-Value store.
  One agent for the primary Key-Value store.
  For sets, another one is used.

  This KV Store is memory-only and therefore temporary.
  """

  def start_link do
    {:ok, kv_store} = Agent.start_link(fn -> %{} end)
    true = Process.register(kv_store, :trkkr_memkv)
    {:ok, kv_store}
  end

  # Errors
  defmodule UndefinedSetError do
    defexception message: "No such set.", plug_status: 500
  end

  # Private helpers
  defp getkvstore do
    Process.whereis(:trkkr_memkv)
  end
  defp updatekv(func) do
    getkvstore()
    |> Agent.update(func)
  end
  defp setupdate!(key, func) do
    if !exists?(key), do: raise UndefinedSetError
    getkvstore()
    |> Agent.get(fn map -> map[key] end)
    |> Agent.update(func)
  end
  defp setupdate(key, func) do
    if !exists?(key), do: set_store(key, [])
    getkvstore()
    |> Agent.get(fn map -> map[key] end)
    |> Agent.update(func)
  end

  # Storing/manipulating operations
  def store(key, value) do
    updatekv(fn map->
      Map.put(map, key, value)
    end)
  end
  def add(key, num \\ 1) do
    updatekv(fn map ->
      case map[key] do
        nil -> Map.put(map, key, num)
        x -> Map.put(map, key, x + num)
      end
    end)
  end
  def substract(key, num \\ 1) do
    updatekv(fn map ->
      case map[key] do
        nil -> Map.put(map, key, num)
        x -> Map.put(map, key, x - num)
      end
    end)
  end
  def set_store(key, values \\ []) do
    updatekv(fn map ->
      {:ok, set_agent} = Agent.start_link(fn -> values end)
      Map.put(map, key, set_agent)
    end)
  end
  def set_add(key, value) do
    setupdate!(key, fn set ->
      if !Enum.member?(set, value) do
        set ++ [value]
      else
        set
      end
    end)
  end

  # Fetching operations
  def fetch(key) do
    getkvstore()
    |> Agent.get(fn map -> map[key] end)
  end
  def set_fetch(key) do
    if !exists?(key), do: raise UndefinedSetError
    fetch(key)
    |> Agent.get(fn set -> set end)
  end

  # Delete operations
  def delete(key) do
    store(key, nil)
  end
  def set_remove(key, value) do
    setupdate(key, fn set ->
      set
      |> Enum.filter(fn x -> x != value end)
    end)
  end
  def set_delete(key) do 
    set = fetch(key)
    if set do
      Agent.stop(set)
      store(key, nil)
    end
    :ok
  end

  # Listing/finding operations
  def list() do
    getkvstore()
    |> Agent.get(fn map -> Map.keys(map) end)
  end
  def find(beginning \\ "") do
    list()
    |> Enum.filter(fn k -> k |> String.starts_with?(beginning) end)
  end

  # Checking functions
  def exists?(key) do
    getkvstore()
    |> Agent.get(fn map -> map[key] != nil end)
  end
  def set_length?(key) do
    if exists?(key) do
      fetch(key)
      |> Agent.get(fn map -> length(map) end)
    end
  end
end
