# Main Plug stuff.
# Glues all the stuff together.

require IEx

defmodule Trkkr.Plug.Main do
  @moduledoc """
  This module combines all the Plug modules we have got and makes them actually do stuff.
  """

  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:multipart, :urlencoded]
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
