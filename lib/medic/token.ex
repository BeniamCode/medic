defmodule Medic.Token do
  use Joken.Config

  @impl true
  def token_config do
    default_claims(iss: "medic_mobile", aud: "medic_api")
    |> add_claim("user_id", nil, &(&1 != nil))
    |> add_claim("role", nil, &(&1 in ["doctor", "patient", "admin"]))
  end

  # Helper to generate a token for a user
  def generate_and_sign_for_user(user) do
    claims = %{"user_id" => user.id, "role" => user.role}
    generate_and_sign(claims, signer())
  end

  # Helper to verify a token
  def verify_token(token) do
    verify_and_validate(token, signer())
  end

  # In a real app, use a secret from config
  defp signer do
    Joken.Signer.create("HS256", "z+123456789012345678901234567890123456789012345678901234567890")
  end
end
