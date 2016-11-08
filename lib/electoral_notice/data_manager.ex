defmodule ElectoralNotice.DataManager do
  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Starting DataManager")
    {:ok, nil}
  end

  def handle_cast({:update, new_data}, nil) do
    last_update = Map.get(new_data, "lastupdate")
    last_update_string = Map.get(new_data, "lastupdate_iso8601")
    Logger.info("Setting new payload as de facto #{last_update_string}")
    decoded_data = decode_data(new_data)

    {:noreply, {last_update, decoded_data}}
  end

  def handle_cast({:update, %{"lastupdate" => last_update} = new_data}, {last_update, data}) do
    last_update_string = Map.get(new_data, "lastupdate_iso8601")
    Logger.info("Ignoring data payload because the last updated timestamp was the same: #{last_update_string}")
    {:noreply, {last_update, data}}
  end

  def handle_cast({:update, new_data}, {_, existing_data}) do
    last_update = Map.get(new_data, "lastupdate")
    last_update_string = Map.get(new_data, "lastupdate_iso8601")

    Logger.info("Processing data payload last updated at #{last_update_string}")

    decoded_data = decode_data(new_data)
    detect_changes(decoded_data, existing_data)
    |> publish_changes()

    {:noreply, {last_update, decoded_data}}
  end

  def detect_changes(new_data, existing_data) do
    Enum.reject(new_data, fn {state, data} ->

      new_democratic_electoral_votes = Map.get(data, "democrat")
      new_republican_electoral_votes = Map.get(data, "republican")

      existing_state_data = Map.get(existing_data, state)
      old_democratic_electoral_votes = Map.get(existing_state_data, "democrat")
      old_republican_electoral_votes = Map.get(existing_state_data, "republican")

      dem = (new_democratic_electoral_votes == old_democratic_electoral_votes)
      rep = (new_republican_electoral_votes == old_republican_electoral_votes)

      dem || rep
    end)
    |> Enum.into(%{})
  end

  def publish_changes(changes) do
    Enum.each(changes, fn {state, data} ->
      democrat_votes = Map.get(data, "democrat")
      republican_votes = Map.get(data, "republican")
      total_votes = Map.get(data, "total")

      GenServer.cast(ElectoralNotice.TwitterPublisher, {:publish, state, total_votes, :democrat, democrat_votes})
      GenServer.cast(ElectoralNotice.TwitterPublisher, {:publish, state, total_votes, :republican, republican_votes})
    end)
  end

  defp decode_data(%{"data" => data}) do
    Enum.map(data, &decode_state_data/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  defp decode_state_data(state_data) do
    state = Map.get(state_data, "state")
    democratic_electoral_votes = Map.get(state_data, "demelectoral")
    republican_electoral_votes = Map.get(state_data, "repelectoral")
    total_electoral_votes = Map.get(state_data, "electoralvotes")

    %{
      state => %{
        "democrat" => democratic_electoral_votes,
        "republican" => republican_electoral_votes,
        "total" => total_electoral_votes
      }
    }
  end
end
