defmodule Medic.CalCom do
  @moduledoc """
  Client for interacting with Cal.com API.
  """

  def client do
    api_key = System.get_env("CAL_COM_API_KEY")
    # Using v1 API as an example. Adjust base_url as needed.
    Req.new(base_url: "https://api.cal.com/v1", params: [apiKey: api_key])
  end

  def list_bookings do
    # Example function to list bookings
    # Response handling should be more robust in production
    case Req.get(client(), url: "/bookings") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "Cal.com API error: #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
