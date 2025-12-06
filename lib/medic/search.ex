defmodule Medic.Search do
  @moduledoc """
  Client for Typesense Search.
  """

  def client do
    host = System.get_env("TYPESENSE_HOST", "localhost")
    port = System.get_env("TYPESENSE_PORT", "8108")
    key = System.get_env("TYPESENSE_API_KEY", "xyz")
    scheme = System.get_env("TYPESENSE_SCHEME", "http")

    Req.new(
      base_url: "#{scheme}://#{host}:#{port}",
      headers: [{"X-TYPESENSE-API-KEY", key}]
    )
  end

  def search(collection, query_params) do
    case Req.get(client(), url: "/collections/#{collection}/documents/search", params: query_params) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status}} -> {:error, "Typesense error: #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
