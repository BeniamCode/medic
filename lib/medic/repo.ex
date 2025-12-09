defmodule Medic.Repo do
  use AshPostgres.Repo,
    otp_app: :medic
end
