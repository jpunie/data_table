# DataTable

[Docs](https://hexdocs.pm/data_table/DataTable.html)

A flexible DataTable component for LiveView.

![Screenshot of simple DataTable usage](screenshot.png "Simple DataTable usage")
[Source code for the screenshot above. You get all of this in ~50loc.](https://github.com/hansihe/data_table/blob/main/example/lib/example_web/live/articles.ex)

Some of the features the component has:
* Filtering
* Sorting
* Expandable rows
* Pagination
* Row selection with customizable bulk actions
* Data is fetched from `DataTable.Source` behaviour, usable with custom data sources
* First class Ecto `Source`
* Support for persisting sort/filter state to query string
* Tailwind theme included, but fully customizable

```elixir
def render(assigns) do
  ~H"""
  <DataTable.live_data_table
    id="table"
    source={{DataTable.Ecto, {MyApp.Repo, @source_query}}}>

    <:col :let={row} name="Id" fields={[:id]} sort_field={:id}>
      <%= row.id %>
    </:col>

    <:col :let={row} name="Name" fields={[:first_name, :last_name]}>
      <%= row.first_name <> " " <> row.last_name %>
    </:col>

  </DataTable.live_data_table>
  """
end

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

## Installation
First you need to add `data_table` to your `mix.exs`:

```elixir
defp deps do
  [
    {:data_table, "~> 1.0"}
  ]
end
```

If you want to use the default `Tailwind` theme, you need to set up `tailwind` to include styles
from the `data_table` dependency.

Add this to the `content` list in your `assets/tailwind.js`:
```js
"../deps/data_table/**/*.*ex"
```

## Persisting table preferences

The table saves the selected page size and visible columns in browser local storage by
default. Register the hook in your application's LiveView JavaScript, and rebuild your
assets after upgrading:

```js
import {DataTablePreferences} from "../../deps/data_table/assets/data_table_preferences.mjs"

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {DataTablePreferences}
})
```

Merge the hook into your existing `hooks` object if you already have one. Without the
registered hook, browser persistence cannot work. Storage is per browser and origin,
not per authenticated user; do not use it for sensitive data. The default key is
`data_table:<table id>`; supply `preference_key` to distinguish tables or users.
Storage errors and invalid data are reported in the browser console or server log.
Preferences are restored after the LiveView connects, so the default table may briefly
appear first. Set `preference_storage={:none}` to disable persistence.

To save preferences in your own backend instead, pass `preference_storage={:parent}`,
provide `preferences`, and handle updates in the parent LiveView:

```elixir
<DataTable.live_data_table
  id="orders"
  source={@source}
  preference_storage={:parent}
  preferences={@table_preferences}
  handle_preferences={fn preferences -> send(self(), {:save_table_preferences, preferences}) end}>
  ...
</DataTable.live_data_table>
```

Load `@table_preferences` before rendering, or assign it later after an asynchronous
load; changed assigns are applied to the table. The callback receives the complete map
`%{table_id: "orders", page_size: 25, visible_columns: ["id", "name"]}`. `table_id`
is the table's `id` and identifies which table changed. Column IDs are the lowercased
`:col` names (not their labels); `page_size: nil` means all rows, and `[]` hides all
columns. Either key may be omitted when initializing, to retain its default.
Persist the map and update the assign in the parent as appropriate; restoring it does
not invoke the callback. Unknown saved column IDs are ignored with a server warning.

An explicit `nav` page size takes precedence over a restored preference. A `nil`
navigation page size means no override; use `:all` for an explicit unlimited override.
Changing visible columns while a navigation override is active does not replace the
saved page-size preference. Choosing a page size explicitly updates that preference.
