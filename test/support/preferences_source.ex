defmodule DataTable.PreferencesTest.Source do
  @behaviour DataTable.Source

  defdelegate query(source, query), to: DataTable.List
  defdelegate filterable_fields(source), to: DataTable.List
  defdelegate key(source), to: DataTable.List

  def filter_types(_source) do
    %{all: %{validate: fn _op, _value -> true end, ops: [contains: "contains"]}}
  end
end
