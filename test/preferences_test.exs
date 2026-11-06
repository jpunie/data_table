defmodule DataTable.PreferencesTest.Live do
  use Phoenix.LiveView

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       table_id: Map.get(session, "table_id", "preferences-table"),
       storage: Map.get(session, "storage", :local_storage),
       preferences: Map.get(session, "preferences"),
       nav: Map.get(session, "nav"),
       theme: Map.get(session, "theme", DataTable.Theme.Tailwind),
       preference_key: Map.get(session, "preference_key"),
       test_pid: Map.get(session, "test_pid")
     )}
  end

  def handle_info({:preferences, preferences}, socket),
    do: {:noreply, assign(socket, :preferences, preferences)}

  def render(assigns) do
    ~H"""
    <DataTable.live_data_table
      id={@table_id}
      source={{DataTable.PreferencesTest.Source, {Enum.map(1..60, &%{id: &1, name: "Row #{&1}"}), %DataTable.List.Config{}}}}
      filter_enabled={false}
      theme={@theme}
      nav={@nav}
      preference_storage={@storage}
      preference_key={@preference_key}
      preferences={@preferences}
      handle_preferences={fn preferences -> send(@test_pid, {:preferences_changed, preferences}) end}
    >
      <:col name="Id" fields={[:id]} :let={row}><%= row.id %></:col>
      <:col name="Name" fields={[:name]} :let={row}><%= row.name %></:col>
    </DataTable.live_data_table>
    """
  end
end

defmodule DataTable.PreferencesTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest
  import ExUnit.CaptureLog

  @endpoint DataTable.TestEndpoint

  defp table(session \\ %{}) do
    {:ok, view, _} =
      live_isolated(Phoenix.ConnTest.build_conn(), DataTable.PreferencesTest.Live,
        session: session
      )

    view
  end

  defp restore(view, preferences) do
    render_hook(
      element(view, "#preferences-table-preferences"),
      "restore-preferences",
      preferences
    )
  end

  test "local preferences restore columns and page size and user changes are emitted" do
    view = table()

    assert has_element?(
             view,
             "#preferences-table-preferences[phx-hook='DataTablePreferences'][data-preference-key='data_table:preferences-table']"
           )

    restore(view, %{"page_size" => 25, "visible_columns" => ["name"]})
    refute has_element?(view, "thead th", "Id")
    assert has_element?(view, "thead th", "Name")
    assert has_element?(view, "tbody tr:nth-child(25)")
    refute has_element?(view, "tbody tr:nth-child(26)")

    render_click(element(view, "#dropdown_preferences-table [phx-value-field='id']"))

    assert_push_event(view, "data-table:preferences", %{
      id: "preferences-table",
      preferences: %{page_size: 25, visible_columns: ["id", "name"]}
    })

    render_change(element(view, "form[phx-change='change-page-size']"), %{"page_size" => "all"})
    assert has_element?(view, "select option[value='all'][selected]")
    assert has_element?(view, "tbody tr:nth-child(60)")

    assert_push_event(view, "data-table:preferences", %{
      preferences: %{page_size: nil, visible_columns: ["id", "name"]}
    })
  end

  test "late restoration cannot overwrite a user's changes" do
    view = table()
    render_click(element(view, "#dropdown_preferences-table [phx-value-field='name']"))
    restore(view, %{"page_size" => 25, "visible_columns" => ["name"]})
    assert has_element?(view, "thead th", "Id")
    refute has_element?(view, "thead th", "Name")
    refute has_element?(view, "tbody tr:nth-child(11)")
  end

  test "parent preferences initialize, update, and notify without a browser hook" do
    view =
      table(%{
        "storage" => :parent,
        "preferences" => %{page_size: nil, visible_columns: ["name"]},
        "test_pid" => self()
      })

    refute has_element?(view, "#preferences-table-preferences[phx-hook]")
    assert has_element?(view, "tbody tr:nth-child(60)")
    refute has_element?(view, "thead th", "Id")
    refute_received {:preferences_changed, _}

    render_click(element(view, "#dropdown_preferences-table [phx-value-field='id']"))

    assert_receive {:preferences_changed,
                    %{
                      table_id: "preferences-table",
                      page_size: nil,
                      visible_columns: ["id", "name"]
                    }}

    render_change(element(view, "form[phx-change='change-page-size']"), %{"page_size" => "25"})

    assert_receive {:preferences_changed,
                    %{
                      table_id: "preferences-table",
                      page_size: 25,
                      visible_columns: ["id", "name"]
                    }}

    send(view.pid, {:preferences, %{page_size: 50, visible_columns: ["id"]}})
    assert has_element?(view, "tbody tr:nth-child(50)")
    refute has_element?(view, "thead th", "Name")
  end

  test "explicit nav page size wins over local and parent preferences" do
    nav = %DataTable.NavState{set: MapSet.new([:page_size]), page_size: 50}
    view = table(%{"nav" => nav})
    restore(view, %{"page_size" => 25, "visible_columns" => ["name"]})
    assert has_element?(view, "tbody tr:nth-child(50)")
    refute has_element?(view, "tbody tr:nth-child(51)")
    refute has_element?(view, "thead th", "Id")

    view = table(%{"storage" => :parent, "nav" => nav, "preferences" => %{page_size: 25}})

    assert has_element?(view, "tbody tr:nth-child(50)")
  end

  test "parent callback identifies each table" do
    orders = table(%{"table_id" => "orders", "storage" => :parent, "test_pid" => self()})
    users = table(%{"table_id" => "users", "storage" => :parent, "test_pid" => self()})

    render_change(element(orders, "form[phx-change='change-page-size']"), %{"page_size" => "25"})
    assert_receive {:preferences_changed, %{table_id: "orders", page_size: 25}}

    render_change(element(users, "form[phx-change='change-page-size']"), %{"page_size" => "50"})
    assert_receive {:preferences_changed, %{table_id: "users", page_size: 50}}
  end

  test "column changes preserve saved page size under a navigation override" do
    nav = %DataTable.NavState{set: MapSet.new([:page_size]), page_size: :all}
    view = table(%{"nav" => nav})
    restore(view, %{"page_size" => 25, "visible_columns" => ["name"]})
    assert has_element?(view, "tbody tr:nth-child(60)")

    render_click(element(view, "#dropdown_preferences-table [phx-value-field='id']"))

    assert_push_event(view, "data-table:preferences", %{
      preferences: %{page_size: 25, visible_columns: ["id", "name"]}
    })
  end

  test "stale column ids are logged and valid ids still restore" do
    view = table()

    log =
      capture_log(fn ->
        restore(view, %{"visible_columns" => ["name", "removed"]})
      end)

    assert log =~ "unknown column ids"
    assert has_element?(view, "thead th", "Name")
    refute has_element?(view, "thead th", "Id")
  end

  test "invalid browser data is logged and ignored" do
    view = table()
    log = capture_log(fn -> restore(view, %{"page_size" => 0, "visible_columns" => ["name"]}) end)
    assert log =~ "invalid browser preferences"
    assert has_element?(view, "thead th", "Id")
    refute has_element?(view, "tbody tr:nth-child(11)")
  end

  test "basic theme and disabled storage support unlimited page size" do
    view = table(%{"theme" => DataTable.Theme.Basic, "storage" => :none})
    refute has_element?(view, "#preferences-table-preferences[phx-hook]")
    render_change(element(view, "form[phx-change='change-page-size']"), %{"page_size" => "all"})
    assert has_element?(view, "tbody tr:nth-child(60)")
    assert has_element?(view, "select option[value='all'][selected]")
    refute_push_event(view, "data-table:preferences", _)
  end

  test "a custom storage key is rendered for the browser hook" do
    view = table(%{"preference_key" => "orders:user-1"})

    assert has_element?(
             view,
             "#preferences-table-preferences[data-preference-key='orders:user-1']"
           )
  end
end
