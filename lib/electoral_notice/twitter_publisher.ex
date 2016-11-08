defmodule ElectoralNotice.TwitterPublisher do
  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting TwitterPublisher")
    {:ok, nil}
  end

  def handle_cast({:publish, state, total_votes, :democrat, votes}, _state) do
    msg = message(state, total_votes, :democrat, votes)
    Logger.info(msg)
    ExTwitter.update(msg)
    {:noreply, nil}
  end

  def handle_cast({:publish, state, total_votes, :republican, votes}, _state) do
    # Not reporting Republican vote to Twitter currently, just write to log
    msg = message(state, total_votes, :republican, votes)
    Logger.info(msg)
    {:noreply, nil}
  end

  def message(state, total_votes, party, votes) do
    party_name = name(party)
    "[TESTING] #{state}: #{votes} out of #{total_votes} electoral votes assigned to #{party_name} candidate"
  end

  def name(:democrat), do: "DEMOCRATIC"
  def name(:republican), do: "REPUBLICAN"
end
