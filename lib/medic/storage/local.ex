defmodule Medic.Storage.Local do
  @moduledoc """
  Simple local-disk storage used in non-production environments.

  Files are written under `priv/static/uploads/` so they can be served via `Plug.Static`.
  """

  @spec upload(binary(), binary(), binary()) :: {:ok, binary()} | {:error, term()}
  def upload(file_binary, _content_type, file_name)
      when is_binary(file_binary) and is_binary(file_name) do
    root = uploads_root_dir()

    if unsafe_path?(file_name) do
      {:error, :invalid_path}
    else
      relative_path = Path.join(["uploads", file_name])
      disk_path = Path.join(root, file_name)

      with :ok <- File.mkdir_p(Path.dirname(disk_path)),
           :ok <- File.write(disk_path, file_binary) do
        {:ok, "/" <> relative_path}
      end
    end
  end

  defp uploads_root_dir do
    custom = Application.get_env(:medic, Medic.Storage, []) |> Keyword.get(:local_uploads_dir)

    cond do
      is_binary(custom) and custom != "" ->
        custom

      true ->
        priv = :code.priv_dir(:medic) |> to_string()
        Path.join([priv, "static", "uploads"])
    end
  end

  defp unsafe_path?(path) do
    String.contains?(path, "..") or String.starts_with?(path, "/") or
      String.starts_with?(path, "\\")
  end
end
