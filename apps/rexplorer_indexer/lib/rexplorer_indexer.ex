defmodule RexplorerIndexer do
  @moduledoc """
  Chain data ingestion application for Rexplorer.

  This app is responsible for fetching blocks, transactions, and events from
  blockchain nodes and persisting them through the core `Rexplorer` domain layer.

  It has no web dependencies and can be deployed independently from the web layer,
  allowing indexing and serving to scale separately.
  """
end
