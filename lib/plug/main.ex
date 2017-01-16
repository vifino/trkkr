# Main Plug stuff.
# Glues all the plugs together.

defmodule Trkkr.Plug.Main do
  @moduledoc """
  This module combines all the Plug modules we have got and makes them actually do stuff.
  """

  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:multipart, :urlencoded],
                     length: 10_000,
                     read_length: 10_000,
                     read_timeout: 1_000
  plug Trkkr.Plug.TrkkrAPI

  plug :match
  plug :dispatch

  # Routes!
  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "wtf r u doin here")
  end
  post "/" do
    conn
    |> send_resp(200, "pls.")
  end

  match _ do
    send_resp(conn, 404, "Where the fuck do you think you are going?")
  end
end
