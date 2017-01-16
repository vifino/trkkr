# Init code and stuff.

defmodule Trkkr do
  @moduledoc """
  Main code for Trkkr, a BitTorrent tracker.
  This should initialize stuff and eventually bring up
  the Plug-based API and (future) web UI.
  """
  use Application
  
  def start(_type, _args) do
    IO.puts "Starting up..."
    import Supervisor.Spec

    port = Application.get_env(:trkkr, :port, 8080)

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Trkkr.Plug.Main, [], port: port),
      worker(Trkkr.Storage.Memory, []),
      worker(Trkkr.Storage.Redis, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Trkkr)
  end
end
