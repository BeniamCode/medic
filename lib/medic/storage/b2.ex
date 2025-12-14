defmodule Medic.Storage.B2 do
  @moduledoc """
  Minimal Backblaze B2 uploader for small files.

  Uses the official B2 Native API with `Req`.

  Configuration (env-driven via runtime.exs recommended):

    config :medic, __MODULE__,
      key_id: System.get_env("B2_KEY_ID"),
      application_key: System.get_env("B2_APPLICATION_KEY"),
      bucket_id: System.get_env("B2_BUCKET_ID"),
      bucket_name: System.get_env("B2_BUCKET_NAME")

  Bucket must be public if you want stable public URLs without signed auth.
  """

  require Logger

  @spec configured?() :: boolean()
  def configured? do
    cfg = config()

    Enum.all?([cfg[:key_id], cfg[:application_key], cfg[:bucket_id], cfg[:bucket_name]], fn v ->
      is_binary(v) and v != ""
    end)
  end

  @spec upload(binary(), content_type :: binary(), file_name :: binary()) ::
          {:ok, url :: binary()} | {:error, term()}
  def upload(file_binary, content_type, file_name)
      when is_binary(file_binary) and is_binary(content_type) and is_binary(file_name) do
    with {:ok, auth} <- authorize_account(),
         {:ok, upload} <- get_upload_url(auth),
         {:ok, stored_name} <- upload_file(upload, file_binary, content_type, file_name) do
      {:ok, public_url(auth, stored_name)}
    end
  end

  defp config do
    Application.get_env(:medic, __MODULE__, [])
  end

  defp authorize_account do
    cfg = config()

    key_id = cfg[:key_id]
    application_key = cfg[:application_key]

    if not (is_binary(key_id) and is_binary(application_key)) do
      {:error, :not_configured}
    else
      url = "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"

      basic = Base.encode64("#{key_id}:#{application_key}")

      case Req.get(url, headers: [{"Authorization", "Basic #{basic}"}]) do
        {:ok, %{status: 200, body: body}} when is_map(body) ->
          {:ok,
           %{
             api_url: body["apiUrl"],
             download_url: body["downloadUrl"],
             auth_token: body["authorizationToken"]
           }}

        {:ok, %{status: status, body: body}} ->
          Logger.error("B2 authorize failed: #{status} #{inspect(body)}")
          {:error, :authorize_failed}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp get_upload_url(%{api_url: api_url, auth_token: auth_token} = _auth) do
    cfg = config()
    bucket_id = cfg[:bucket_id]

    url = "#{api_url}/b2api/v2/b2_get_upload_url"

    case Req.post(url,
           json: %{bucketId: bucket_id},
           headers: [{"Authorization", auth_token}]
         ) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok,
         %{
           upload_url: body["uploadUrl"],
           upload_auth_token: body["authorizationToken"]
         }}

      {:ok, %{status: status, body: body}} ->
        Logger.error("B2 get_upload_url failed: #{status} #{inspect(body)}")
        {:error, :get_upload_url_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload_file(
         %{upload_url: upload_url, upload_auth_token: upload_auth_token},
         file_binary,
         content_type,
         file_name
       ) do
    encoded_name = encode_b2_file_name(file_name)
    sha1 = :crypto.hash(:sha, file_binary) |> Base.encode16(case: :lower)

    headers = [
      {"Authorization", upload_auth_token},
      {"X-Bz-File-Name", encoded_name},
      {"Content-Type", content_type},
      {"X-Bz-Content-Sha1", sha1}
    ]

    case Req.post(upload_url, headers: headers, body: file_binary) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body["fileName"] || file_name}

      {:ok, %{status: status, body: body}} ->
        Logger.error("B2 upload failed: #{status} #{inspect(body)}")
        {:error, :upload_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp public_url(%{download_url: download_url}, stored_name) do
    cfg = config()
    bucket_name = cfg[:bucket_name]

    # Standard public URL form for public buckets:
    #   <downloadUrl>/file/<bucketName>/<fileName>
    "#{download_url}/file/#{bucket_name}/#{stored_name}"
  end

  defp encode_b2_file_name(name) do
    # B2 expects URL-encoded file names; keep slashes as path separators.
    URI.encode(name, fn ch ->
      URI.char_unreserved?(ch) or ch == ?/
    end)
  end
end
