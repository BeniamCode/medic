defmodule Medic.Repo do
  use Ecto.Repo,
    otp_app: :medic,
    adapter: Ecto.Adapters.SQLite3
end
