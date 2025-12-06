defmodule Mix.Tasks.Search.Setup do
  @moduledoc """
  Sets up Typesense collection and indexes all doctors.

  ## Usage

      mix search.setup

  This will:
  1. Create/recreate the doctors collection in Typesense
  2. Index all verified doctors
  """
  use Mix.Task

  @shortdoc "Sets up Typesense and indexes doctors"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("🔍 Setting up Typesense search...")

    case Medic.Search.create_collection() do
      {:ok, _} ->
        IO.puts("✓ Collection created")

      {:error, reason} ->
        IO.puts("⚠ Collection creation failed: #{inspect(reason)}")
        IO.puts("  Make sure Typesense is running on localhost:8108")
        exit(:shutdown)
    end

    case Medic.Search.sync_all_doctors() do
      {:ok, count} ->
        IO.puts("✓ Indexed #{count} doctors")
        IO.puts("\n✅ Search setup complete!")

      {:error, reason} ->
        IO.puts("✗ Indexing failed: #{inspect(reason)}")
        exit(:shutdown)
    end
  end
end
