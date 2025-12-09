# priv/repo/reindex_search.exs
require Logger

Logger.info("Starting Search Re-indexing...")

case Medic.Search.sync_all_doctors() do
  {:ok, count} ->
    Logger.info("Successfully re-indexed #{count} doctors to Typesense.")
  {:error, reason} ->
    Logger.error("Failed to re-index doctors: #{inspect(reason)}")
end
