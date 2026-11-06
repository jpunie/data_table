defmodule DataTable.TailwindDropdownTest.Source do
  @behaviour DataTable.Source

  defdelegate query(source, query), to: DataTable.List
  defdelegate filterable_fields(source), to: DataTable.List
  defdelegate key(source), to: DataTable.List

  def filter_types(_source) do
    %{all: %{validate: fn _op, _value -> true end, ops: [contains: "contains"]}}
  end
end

defmodule DataTable.TailwindDropdownTest.Live do
  use Phoenix.LiveView

  def mount(_params, _session, socket), do: {:ok, socket}

  def render(assigns) do
    ~H"""
    <DataTable.live_data_table
      id="tailwind-table"
      theme={DataTable.Theme.Tailwind}
      filter_enabled={false}
      nav={%DataTable.NavState{set: MapSet.new()}}
      source={{DataTable.TailwindDropdownTest.Source, {[%{id: 1, name: "One"}], %DataTable.List.Config{}}}}
    >
      <:col name="Id" fields={[:id]} :let={row}><%= row.id %></:col>
      <:col name="Name" fields={[:name]} :let={row}><%= row.name %></:col>
    </DataTable.live_data_table>
    """
  end
end

defmodule DataTable.TailwindDropdownTest do
  use ExUnit.Case
  import Phoenix.LiveViewTest

  @endpoint DataTable.TestEndpoint

  test "column menu stays outside the scrolling table and toggles fields" do
    {:ok, view, _html} =
      live_isolated(Phoenix.ConnTest.build_conn(), DataTable.TailwindDropdownTest.Live)

    assert has_element?(view, "#tailwind-table .overflow-x-auto table")
    assert has_element?(view, "#tailwind-table .overflow-x-auto th.sticky")
    refute has_element?(view, "#tailwind-table .overflow-x-auto #dropdown_tailwind-table")

    assert has_element?(
             view,
             "#dropdown_tailwind-table.absolute.max-w-full[style='display: none;']"
           )

    render_click(element(view, "button[phx-value-dropdown_id='dropdown_tailwind-table']"))
    assert has_element?(view, "#dropdown_tailwind-table[style='display: block;']")
    assert has_element?(view, "thead th", "Name")

    render_click(element(view, "#dropdown_tailwind-table [phx-click='toggle-field']", "Name"))
    refute has_element?(view, "thead th", "Name")
    assert has_element?(view, "#dropdown_tailwind-table[style='display: block;']")

    render_click(element(view, "#dropdown_tailwind-table [phx-click='toggle-field']", "Name"))
    assert has_element?(view, "thead th", "Name")

    render_click(element(view, "button[phx-value-dropdown_id='dropdown_tailwind-table']"))
    assert has_element?(view, "#dropdown_tailwind-table[style='display: none;']")

    render_click(element(view, "button[phx-value-dropdown_id='dropdown_tailwind-table']"))

    view |> with_target("#tailwind-table") |> render_hook("hide-dropdown")

    assert has_element?(view, "#dropdown_tailwind-table[style='display: none;']")
  end
end
