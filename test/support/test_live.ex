defmodule DataTable.TestLive do
  use Phoenix.LiveView

  defmodule Source do
    @behaviour DataTable.Source

    defdelegate query(source, query), to: DataTable.List
    defdelegate filterable_fields(source), to: DataTable.List
    defdelegate key(source), to: DataTable.List

    def filter_types(_source) do
      %{all: %{validate: fn _op, _value -> true end, ops: [contains: "contains"]}}
    end
  end

  def render(assigns) do
    ~H"""
    <% config = %DataTable.List.Config{} %>
    <% data = Enum.map(0..49, &%{id: &1}) %>

    <DataTable.live_data_table
      id="table"
      theme={DataTable.Theme.Basic}
      row_expansion_mode={@row_expansion_mode}
      page_size={20}
      source={{DataTable.TestLive.Source, {data, config}}}>

      <:col name="Id" fields={[:id]} sort_field={:id} :let={row}>
        Row <%= row.id %>
      </:col>

      <:row_expanded fields={[:id]} :let={row}>
        Row Expanded <%= row.id %>
      </:row_expanded>

      <:selection_action label="Test Action" handle_action={fn _, _ -> nil end}/>

    </DataTable.live_data_table>
    """
  end

  def mount(_params, session, socket) do
    {:ok, assign(socket, :row_expansion_mode, Map.get(session, "row_expansion_mode", :normal))}
  end
end
