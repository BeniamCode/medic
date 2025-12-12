defmodule Medic.Repo do
  use AshPostgres.Repo,
    otp_app: :medic

  @doc """
  Declare the minimum supported Postgres version to silence compiler warnings.
  """
  @impl true
  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  @doc """
  Ensure AshPostgres knows which extensions should exist in the database.
  """
  @impl true
  def installed_extensions do
    ["ash-functions"]
  end
end
