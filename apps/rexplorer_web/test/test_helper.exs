{:ok, _} = Application.ensure_all_started(:rexplorer_web)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Rexplorer.Repo, :manual)
