defmodule Medic.Storage do
  @moduledoc """
  A small abstraction for file storage.
  """

  alias Medic.Storage.B2
  alias Medic.Storage.Local

  @spec upload_doctor_profile_image(
          doctor_id :: binary(),
          file_binary :: binary(),
          content_type :: binary(),
          ext :: binary()
        ) ::
          {:ok, url :: binary()} | {:error, term()}
  def upload_doctor_profile_image(doctor_id, file_binary, content_type, ext)
      when is_binary(doctor_id) and is_binary(file_binary) and is_binary(content_type) and
             is_binary(ext) do
    file_name = "doctor_profiles/#{doctor_id}/profile_#{unique_token()}#{ext}"

    adapter = storage_adapter()

    case adapter do
      :b2 ->
        if B2.configured?() do
          B2.upload(file_binary, content_type, file_name)
        else
          {:error, :storage_not_configured}
        end

      :local ->
        Local.upload(file_binary, content_type, file_name)

      _ ->
        {:error, :storage_not_configured}
    end
  end

  defp storage_adapter do
    adapter =
      Application.get_env(:medic, __MODULE__, [])
      |> Keyword.get(:adapter, :auto)

    case adapter do
      :auto ->
        if B2.configured?() do
          :b2
        else
          if Application.get_env(:medic, :env) == :prod do
            :none
          else
            :local
          end
        end

      other ->
        other
    end
  end

  defp unique_token do
    Integer.to_string(System.unique_integer([:positive]))
  end
end
