defmodule DataTable.Ecto do

  @moduledoc """
  This module implements a `DataTable.Source` which fetches data from
  an ecto `Repo`.

  You need to pass it two arguments, a Repo and a Query:
  ```elixir
  <DataTable.live_data_table
    [...]
    source={{DataTable.Ecto, {MyApp.Repo, @source_query}}}/>
  ```

  The repo is a normal `Ecto.Repo`, while the query is a query defined
  using the DSL in `DataTable.Ecto.Query`.

  You usually create your query in the `mount/3` callback of your `LiveView`:

  ```elixir
  def mount(_params, _session, socket) do
    query = DataTable.Ecto.Query.from(
      user in MyApp.User,
      fields: %{
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name
      },
      key: :id
    )

    socket = assign(socket, :source_query, query)

    [...]
  end
  ```

  See `DataTable.Ecto.Query` for a full description of the query DSL.
  """
  @behaviour DataTable.Source

  @impl true
  def query({repo, query}, query_params) do
    require Ecto.Query

    dyn_select =
      query_params.fields
      |> Enum.map(fn col_id ->
        {col_id, Map.fetch!(query.fields, col_id)}
      end)
      |> Enum.into(%{})

    base_ecto_query = Enum.reduce(query_params.filters, query.base, fn
      %{field: :all} = filter, acc ->
        value = filter.value || ""
        Enum.reduce(query.fields, acc, fn {field, field_dyn}, acc ->
          case Map.get(query.filters, field) do
            :string ->
              # If the filter is for a string field, we use ilike to match the value
              where_dyn = Ecto.Query.dynamic(ilike(^field_dyn, ^"%#{String.replace(value, "%", "\\%")}%"))
              Ecto.Query.or_where(acc, ^where_dyn)
            _ ->
              where_dyn = Ecto.Query.dynamic(ilike(fragment("CAST(? AS VARCHAR)", ^field_dyn), ^"%#{String.replace(value, "%", "\\%")}%"))
              Ecto.Query.or_where(acc, ^where_dyn)
            end
        end)
      filter, acc ->
        filter_type = Map.fetch!(query.filters, filter.field)
        field_dyn = Map.fetch!(query.fields, filter.field)

        value = case filter_type do
          :integer ->
            {value, ""} = Integer.parse(filter.value)
            value
          :string ->
            filter.value || ""
          :boolean ->
            filter.value == "true"
        end

        where_dyn = case {filter_type, filter.op} do
          {_, :eq} -> Ecto.Query.dynamic(^field_dyn == ^value)
          {_, :lt} -> Ecto.Query.dynamic(^field_dyn < ^value)
          {_, :gt} -> Ecto.Query.dynamic(^field_dyn > ^value)
          {:string, :contains} -> Ecto.Query.dynamic(like(^field_dyn, ^"%#{String.replace(value, "%", "\\%")}%"))
        end

        Ecto.Query.where(acc, ^where_dyn)
    end)

    ecto_query = maybe_apply(base_ecto_query, query_params.sort, fn ecto_query, {field, dir} ->
      field_dyn = Map.fetch!(query.fields, field)
      Ecto.Query.order_by(ecto_query, ^[{dir, field_dyn}])
    end)

    ecto_query = case query.default_order_by do
      [] ->
        ecto_query
      order_by ->
        Ecto.Query.order_by(ecto_query, ^order_by)
    end

    # Pagination
    ecto_query =
      ecto_query
      |> maybe_apply(query_params.offset, &Ecto.Query.offset(&1, ^&2))
      |> maybe_apply(query_params.limit, &Ecto.Query.limit(&1, ^&2))

    ecto_query = Ecto.Query.select(ecto_query, ^dyn_select)

    # we use a subquery to avoid the count query from being affected
    # by any group_by clauses in the base query. If the base query has a group_by clause,
    # we want to return the number of groups, not the count of each group.
    import Ecto.Query

    count_query = from(
      subquery in subquery(base_ecto_query),
      select: count(subquery)
    )

    results = repo.all(ecto_query)
    count = repo.one(count_query)

    %DataTable.Source.Result{
      results: results,
      total_results: count
    }
  end

  @impl true
  def filterable_fields({_repo, query}) do
    query.filters
    |> Enum.map(fn {col_id, type} ->
      %{
        col_id: col_id,
        type: type
      }
    end)
  end

  @impl true
  def filter_types({_repo, _query}) do
    %{
      all: %{
        validate: fn _op, _val -> true end,
        ops: [
          contains: "contains",
        ]
      },
      string: %{
        validate: fn _op, _val -> true end,
        ops: [
          contains: "contains",
          eq: "="
        ]
      },
      integer: %{
        validate: fn
          _op, nil ->
            false

          _op, val ->
            case Integer.parse(val) do
              {_, ""} -> true
              _ -> false
            end
        end,
        ops: [
          eq: "=",
          lt: "<",
          gt: ">"
        ]
      },
      boolean: %{
        validate: fn _op, val ->
          case val do
            "true" -> true
            "false" -> true
            _ -> false
          end
        end,
        ops: [
          eq: "="
        ]
      }
    }
  end

  @impl true
  def key({_repo, query}), do: query.key

  defp maybe_apply(query, nil, _fun) do
    query
  end

  defp maybe_apply(query, val, fun) do
    fun.(query, val)
  end

end
