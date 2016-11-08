defmodule ElectoralNotice do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ElectoralNotice.TwitterPublisher, []),
      worker(ElectoralNotice.DataFetcher, []),
      worker(ElectoralNotice.DataManager, [])
    ]

    opts = [strategy: :one_for_one, name: Odin.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
