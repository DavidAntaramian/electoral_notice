defmodule ElectoralNotice.DataFetcher do
  require Logger
  use GenServer

  @data_url "https://pollyvote.com/wp-content/plugins/pollyvote/data/index.php?time=current&level=state&type=world_knowledge"

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting DataFetcher")
    timer = Process.send_after(self, :fetch, 1_000)
    {:ok, timer}
  end

  def handle_info(:fetch, timer) do
    Process.cancel_timer(timer)
    Logger.info("Beginning new data fetch process")

    {:ok, new_data} = fetch_new_data()
    GenServer.cast(ElectoralNotice.DataManager, {:update, new_data})
    Logger.info("Finished fetching new data")

    new_timer = Process.send_after(self, :fetch, 30_000)
    {:noreply, new_timer}
  end

  defp fetch_new_data() do
    {:ok, _, _, body} = :hackney.request(:get, @data_url, [], "", [with_body: true])

    Poison.decode(body)
  end
end
