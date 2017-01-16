# Announce header/request parser
# Cleans up the headers.

defmodule Trkkr.Parser.Announce do
  @moduledoc """
    Takes a Plug.Conn and returns a struct containing
    parsed fields of a BitTorrent /announce GET request.
  """

  # Errors
  defmodule InvalidValueError do
    @moduledoc "Raised when a field has an invalid value."
    defexception message: "Invalid field in /announce query string.", plug_status: 400
  end
  defmodule InvalidLengthError do
    @moduledoc "Raised when a field has an invalid value."
    defexception message: "Invalid lenght in /announce query string.", plug_status: 400
  end
  defmodule InvalidConversionError do
    @moduledoc "Raised when there is an invalid type to convert a value to."
    defexception message: "Invalid type to convert value to.", plug_status: 500
  end

  # For cleanup/conversion of headers.
  @allowed_announce_headers %{
    "info_hash" => true,  # 20 byte SHA1 hash
    "peer_id" => true,    # unique 20 byte string
    "port" => true,       # Port, duh.
    "uploaded" => true,   # bytes uploaded in Base-10 ASCII
    "downloaded" => true, # bytes downloaded in Base-10 ASCII
    "left" => true,       # bytes remaining in Base-10 ASCII
    "compact" => true,    # true if accepting a compact response
    "no_peer_id" => true, # doesn't want peer ids, ignore if compact
    "event" => true,      # one of "started", "stopped", "completed" or not set
    "ip" => true,         # optionally specify alternative IP to connect to
    "numwant" => true,    # number of peers wanted, 0 is allowed
    "key" => true,        # optional ID to prove their identity when their IP changes
    "trackerid" => true   # if previous announce contained tracker id, it should be set here
  }

  @announce_header_conversions %{
    "compact" => :bool,
    "no_peer_id" => :bool,
    "uploaded" => :b10_int,
    "downloaded" => :b10_int,
    "left" => :b10_int,
    "numwant" => :b10_int,
  }

  @announce_length_check %{
    "info_hash" => 20,
    "peer_id" => 20,
  }

  defp fixup_values!(input, conversions, length) do
    input |> Trkkr.Helpers.pmap(fn {k, v} ->
        newval = case conversions[k] do
          :bool ->
            case v do
              "1" -> true
              "0" -> false
              _ -> raise InvalidValueError
            end
          :b10_int-> String.to_integer(v)
          nil -> v
          _ -> raise InvalidConversionError
        end
        fixed_length = length[k]
        if fixed_length do
          if fixed_length != byte_size(newval), do: raise InvalidLengthError
        end
        {k, newval}
    end)
  end

  def parse!(query_params) do
    query_params
    |> Enum.filter(fn {k, _} -> @allowed_announce_headers[k] != nil end)
    |> fixup_values!(@announce_header_conversions, @announce_length_check)
    |> Enum.reduce(%{}, fn({k, v}, ret) -> Map.put(ret, k, v) end) 
  end
end
