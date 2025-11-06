defmodule DataTable.Theme.Tailwind do
  @doc """
  A modern data table theme implemented using Tailwind.

  Design inspired by https://www.figma.com/community/file/1021406552622495462/data-table-design-components-free-ui-kit
  by HBI Agency and Violetta Nekrasova according to CC BY 4.0.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import DataTable.Theme.Tailwind.Components

  alias DataTable.Theme.Util

  # If using this module as the base for your own theme, you may wish to use the
  # upstream libraries instead of these vendored versions.
  # From `:heroicons` Heroicons
  alias DataTable.Theme.Tailwind.Heroicons
  # From `:petal_components` PetalComponents.Dropdown`
  alias DataTable.Theme.Tailwind.Dropdown

  attr(:size, :atom, default: :small, values: [:small, :medium, :large])
  slot(:icon)
  slot(:inner_block, required: true)

  def btn_basic(assigns) do
    ~H"""
    <% classes = [
      "cursor-pointer",
      "inline-flex items-center justify-center border-primary-400 dark:border-primary-400 dark:hover:border-primary-300 dark:hover:text-primary-300 dark:hover:bg-transparent",
      "dark:text-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-primary-500/50",
      (if @size == :small, do: "text-sm px-2 py-1 space-x-1"),
      (if @size == :small and @icon != nil, do: "pl-1.5"),
      (if @size == :medium, do: ""),
      (if @size == :medium and @icon == nil, do: ""),
      (if @size == :large, do: ""),
      (if @size == :large and @icon == nil, do: "")
    ] %>

    <div tabindex="0" class={classes}>
      <%= render_slot(@icon) %>
      <div><%= render_slot(@inner_block) %></div>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def btn_icon(assigns) do
    ~H"""
    <div tabindex="0" class={[
      "cursor-pointer mr-2",
      "inline-flex items-center justify-center border-primary-400 dark:border-primary-400 dark:hover:border-primary-300 dark:hover:text-primary-300 dark:hover:bg-transparent",
      "dark:text-primary-400 hover:border-primary-600 text-primary-600 hover:text-primary-700 active:bg-primary-200 hover:bg-primary-50 focus:border-primary-700 focus:shadow-primary-500/50",
      "rounded-full w-7 h-7",
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField)
  attr(:options, :any)

  def select(assigns) do
    ~H"""
    <select
      name={@field.name}
      class={[
        "block w-full py-1 pl-3 pr-10 text-sm rounded-lg cursor-pointer",
        "border-gray-300 focus:border-primary-500 focus:ring-primary-500",
        "disabled:bg-gray-100 disabled:cursor-not-allowed focus:outline-none",
        "dark:border-gray-600 dark:focus:border-primary-500 dark:disabled:bg-gray-700 dark:text-gray-300 dark:bg-gray-800",
      ]}>
      <%= for {id, name} <- @options do %>
        <option value={id} selected={@field.value == id}><%= name %></option>
      <% end %>
    </select>
    """
  end

  attr(:field, Phoenix.HTML.FormField)

  def text_input(assigns) do
    ~H"""
    <% has_error = @field.errors != [] %>
    <input
      type="text"
      name={@field.name}
      value={@field.value}
      class={[
        "block w-full pl-2 py-1 rounded-lg shadow-sm border-gray-300 sm:text-sm",
        "focus:border-primary-500 focus:ring-primary-500 focus:outline-none",
        "dark:border-gray-600 dark:focus:border-primary-500 dark:bg-gray-800 dark:text-gray-300 dark:disabled:bg-gray-700",
        "disabled:bg-gray-100 disabled:cursor-not-allowed",
        (if has_error, do: "outline outline-red-600 !bg-red-50")
      ]}/>
    """
  end

  def root(assigns) do
    ~H"""
    <div>
      <.filter_header
        :if={@filter_enabled}
        gettext={@gettext}
        filters_form={@filters_form}
        can_select={@static.can_select}
        has_selection={@has_selection}
        selection_actions={@static.selection_actions}
        target={@target}
        top_right_slot={@top_right}
        filter_column_order={@static.filter_column_order}
        filter_columns={@static.filter_columns}
        filters_fields={@static.filters_fields}/>
     <div :if={!@filter_enabled} class="sm:flex sm:justify-between mt-14"/>

      <div class="mb-2" :if={@static.can_select and @has_selection}>
          <Dropdown.dropdown label={DataTable.Gettext.gettext(@gettext, "Selection")} placement="right">
            <Dropdown.dropdown_menu_item
              :for={%{label: label, action_idx: idx} <- @static.selection_actions}
              label={label}
              phx-click="selection-action"
              phx-value-action-idx={idx}
              phx-target={@target}/>
          </Dropdown.dropdown>
        </div>


      <div class="flex flex-col">
        <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden shadow border border-gray-300 dark:border-gray-700 md:rounded-lg">
              <table class="min-w-full divide-y divide-gray-300 bg-white dark:divide-gray-900 dark:bg-gray-800">
                <.table_header
                  can_select={@static.can_select}
                  header_selection={@header_selection}
                  target={@target}
                  can_expand={@static.can_expand}
                  row_expanded_slot={@row_expanded}
                  header_fields={@header_fields}
                  togglable_fields={@togglable_fields}/>

                <.table_body
                  rows={@rows}
                  conditional_row_class={@static.conditional_row_class || fn _ -> "" end}
                  can_select={@static.can_select}
                  field_slots={@field_slots}
                  has_row_buttons={@static.has_row_buttons}
                  row_buttons_slot={@static.row_buttons_slot}
                  can_expand={@static.can_expand}
                  row_expanded_slot={@row_expanded}
                  target={@target}/>

                <.table_footer
                  gettext={@gettext}
                  page_start_item={@page_start_item}
                  page_end_item={@page_end_item}
                  total_results={@total_results}
                  page={@page}
                  page_size={@page_size}
                  target={@target}
                  has_prev={@has_prev}
                  has_next={@has_next}/>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def filter_header(assigns) do
    ~H"""
    <div class="sm:flex sm:justify-between">
      <div class="flex items-center">
        <.filters_form
          target={@target}
          gettext={@gettext}
          filters_form={@filters_form}
          filter_column_order={@filter_column_order}
          filter_columns={@filter_columns}
          filters_fields={@filters_fields}/>
      </div>

      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <%= if assigns[:top_right_slot] do %>
          <%= render_slot(@top_right_slot) %>
        <% end %>
      </div>
    </div>
    """
  end

  def table_header(assigns) do
    ~H"""
    <thead>
      <tr>
        <th :if={@can_select} scope="col" class="w-10 pl-4 !border-0 text-gray-700 bg-gray-50 dark:bg-gray-700 dark:text-gray-300">
          <.checkbox state={@header_selection} on_toggle="toggle-all" phx-target={@target}/>
        </th>

        <th :if={@can_expand} scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibol w-10 sm:pl-6 !border-0 text-gray-700 bg-gray-50 dark:bg-gray-700 dark:text-gray-300"></th>

        <th
            :for={{field, idx} <- Enum.with_index(@header_fields)}
            scope="col"
            class={[
              "px-6 py-3 text-xs font-medium tracking-wider text-left uppercase text-gray-700 bg-gray-50 dark:bg-gray-700 dark:text-gray-300",
              (if idx == 0, do: "!border-0")
              ]}>
          <div class="flex items-center justify-between">
            <a :if={not field.can_sort} class="group inline-flex">
              <%= field.label %>
            </a>

            <a :if={field.can_sort} href="#" class="group inline-flex" phx-click="cycle-sort" phx-target={@target} phx-value-sort-toggle-id={field.sort_toggle_id}>
              <%= field.label %>

              <span :if={field.sort == :asc} class="ml-2 flex-none items-center rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                <Heroicons.chevron_down mini class="h-4 w-4"/>
              </span>

              <span :if={field.sort == :desc} class="ml-2 flex-none items-center rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                <Heroicons.chevron_up mini class="h-4 w-4"/>
              </span>
            </a>

            <%!-- <a :if={field.can_filter} class="text-gray-400" href="#" phx-click="add-field-filter" phx-target={@target} phx-value-filter-id={field.filter_field_id}>
              <Heroicons.funnel class="h-4 w-4"/>
            </a> --%>
          </div>
        </th>

        <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6 w-0 whitespace-nowrap !border-0 text-gray-700 bg-gray-50 dark:bg-gray-700 dark:text-gray-300">
          <span class="sr-only">Buttons</span>
          <div class="flex justify-end content-center">
            <Dropdown.dropdown>
              <:trigger_element>
                <Heroicons.list_bullet mini class="h-4 w-4"/>
              </:trigger_element>

              <div class="p-4 top-4 right-0 rounded border-gray-300 dark:border-gray-700 space-y-2">
                <div :for={{name, id, checked} <- @togglable_fields} class="relative flex items-start cursor-pointer" phx-click="toggle-field" phx-target={@target} phx-value-field={id}>
                  <div class="flex h-5 w-5 items-center">
                    <div class="border border-gray-300 dark:border-gray-700 rounded relative w-[18px] h-[18px]">
                      <Heroicons.check :if={checked} solid={true} class="w-4"/>
                    </div>
                  </div>
                  <div class="ml-2 text-sm">
                    <label for="comments" class="font-medium"><%= name %></label>
                  </div>
                </div>
              </div>
            </Dropdown.dropdown>
          </div>
        </th>
      </tr>
    </thead>
    """
  end

  def table_body(assigns) do
    ~H"""
    <tbody>
      <%= for {row, idx} <- Enum.with_index(@rows) do %>
        <% conditional_row_class = @conditional_row_class.(row.data) %>
        <% row_class = if rem(idx, 2) == 0, do: "bg-base-100 dark:bg-gray-800", else: "bg-base-400 dark:bg-gray-600" %>
        <tr class={[row_class, "border-b border-gray-300 dark:border-gray-700 last:border-none", conditional_row_class]}>
          <td :if={@can_select} class="pl-4 !border-0">
            <.checkbox state={row.selected} on_toggle="toggle-row" phx-target={@target} phx-value-id={row.id}/>
          </td>

          <td :if={@can_expand} class={[row_class, "cursor-pointer !border-0", conditional_row_class]} phx-click={JS.push("toggle-expanded", page_loading: true)} phx-target={@target} phx-value-data-id={row.id}>
            <% class = if @can_select, do: "ml-5", else: "ml-3" %>
            <Heroicons.chevron_up :if={row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
            <Heroicons.chevron_down :if={not row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
          </td>

          <td
              :for={{field_slot, idx} <- Enum.with_index(@field_slots)}
              class={[row_class, "px-6 py-4 text-sm text-gray-500 dark:text-gray-400", field_slot[:class] || "", (if idx == 0, do: "!border-0"), conditional_row_class]}>
            <%= render_slot(field_slot, row.data) %>
          </td>

          <td class={[row_class, "relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm sm:pr-6 !border-0", conditional_row_class]}>
            <%= if @has_row_buttons do %>
              <%= render_slot(@row_buttons_slot, row.data) %>
            <% end %>
          </td>
        </tr>

        <tr :if={row.expanded} class="bg-white border-b border-gray-300 dark:border-gray-700 dark:bg-gray-800 last:border-none;">
          <td colspan="50">
            <%= render_slot(@row_expanded_slot, row.data) %>
          </td>
        </tr>
      <% end %>
    </tbody>
    """
  end

  def table_footer(assigns) do
    ~H"""
    <tfoot class="!border-0">
      <tr class="px-6 py-3 text-xs font-medium tracking-wider text-left uppercase text-gray-700 bg-gray-50 dark:bg-gray-700 dark:text-gray-300">
        <td colspan="20" class="py-2 px-4">
          <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
            <div>
              <p class="text-sm ">
                <%= DataTable.Gettext.gettext(@gettext, "Showing") %>
                <span :if={@total_results == 0} class="font-medium">0</span>
                <span :if={@total_results > 0} class="font-medium"><%= @page_start_item + 1 %></span>
                <%= DataTable.Gettext.gettext(@gettext, "to") %>
                <span class="font-medium"><%= @page_end_item %></span>
                <%= DataTable.Gettext.gettext(@gettext, "of") %>
                <span class="font-medium"><%= @total_results %></span>
              </p>
            </div>
            <div>
              <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                <a :if={@has_prev} phx-click="change-page" phx-target={@target} phx-value-page={@page - 1} class="inline-flex items-center justify-center rounded-l-md leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-white text-gray-600 hover:bg-gray-50 hover:text-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-400">
                  <span class="sr-only">Previous</span>
                  <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                </a>
                <a :if={not @has_prev} class="inline-flex items-center justify-center rounded-l-md leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300">
                  <span class="sr-only">Previous</span>
                  <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                </a>

                <DataTable.Theme.Util.render_pages page={@page} page_size={@page_size} total_results={@total_results} target={@target} />

                <a :if={@has_next} phx-click="change-page" phx-target={@target} phx-value-page={@page + 1} class="inline-flex items-center justify-center rounded-r-md leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-white text-gray-600 hover:bg-gray-50 hover:text-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-400">
                  <span class="sr-only">Next</span>
                  <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                </a>
                <a :if={not @has_next} class="inline-flex items-center justify-center rounded-r-md leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300">
                  <span class="sr-only">Next</span>
                  <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                </a>
              </nav>
            </div>
          </div>
        </td>
      </tr>
    </tfoot>
    """
  end

  # defp op_options_and_default(_spec, nil), do: {[], ""}
  # defp op_options_and_default(spec, field_value) do
  #  atom_field = String.to_existing_atom(field_value)
  #  filter_data = Enum.find(spec.filterable_columns, & &1.col_id == atom_field)

  #  if filter_data == nil do
  #    {[], ""}
  #  else
  #    type_map = spec.filter_types[filter_data[:type]] || %{}
  #    ops = type_map[:ops] || []
  #    kvs = Enum.map(ops, fn {filter_id, filter_name} -> {filter_name, filter_id} end)

  #    default_selected = case ops do
  #      [] -> ""
  #      [{id, _} | _] -> id
  #    end

  #    {kvs, default_selected}
  #  end
  # end

  # attr :form, :any
  # attr :target, :any
  # attr :spec, :any

  # attr :filters_fields, :any
  # attr :filterable_fields, :any

  attr(:target, :any)
  attr(:gettext, :any)
  attr(:filters_form, :any)
  attr(:filter_column_order, :any)
  attr(:filter_columns, :any)
  attr(:filters_fields, :any)
  attr(:update_filters, :any)

  def filters_form(assigns) do
    ~H"""
    <.form for={@filters_form} phx-target={@target} phx-change="filters-change" phx-submit="filters-change" class="py-3 sm:flex items-start">
      <!-- <div aria-hidden="true" class="hidden h-5 w-px bg-gray-300 sm:ml-4 sm:block"></div> -->

      <div class="min-h-[32px] flex flex-row items-stretch">
        <div class="flex flex-col space-y-2">
          <.inputs_for :let={filter} field={@filters_form[:filters]}>
            <div class="flex flex-row space-x-2">
              <input
                type="hidden"
                name="filters[filters_sort][]"
                value={filter.index}
              />

              <.select
                field={filter[:field]}
                options={Enum.map(@filter_column_order, fn id -> {id, @filter_columns[id].label} end)}/>

              <% field_config = @filter_columns[filter[:field].value] %>
              <.select
                :if={field_config == nil}
                field={filter[:op]}
                options={[]}/>
              <.select
                :if={field_config != nil}
                field={filter[:op]}
                options={Enum.map(field_config.ops_order, fn op_id ->
                  {op_id, DataTable.Gettext.gettext(@gettext, field_config.ops[op_id].name)}
                end)}/>

              <.text_input :if={field_config.type_name != :boolean} field={filter[:value]}/>
              <.select
                :if={field_config.type_name == :boolean}
                field={filter[:value]}
                options={[{"", DataTable.Gettext.gettext(@gettext, "Choose...")}, {"true", DataTable.Gettext.gettext(@gettext, "Yes")}, {"false", DataTable.Gettext.gettext(@gettext, "No")}]}/>

              <label>
                <input type="checkbox" name="filters[filters_drop][]" value={filter.index} class="hidden"/>
                <.btn_icon >
                  <Heroicons.trash class="w-4"/>
                </.btn_icon>
              </label>
            </div>
          </.inputs_for>

        </div>
          <div class={["flex flex-col space-y-2 justify-end"]}>
            <label>
              <input type="checkbox" name="filters[filters_sort][]" class="hidden"/>
              <.btn_basic>
                <:icon>
                  <Heroicons.plus class="w-4"/>
                </:icon>
                {DataTable.Gettext.gettext(@gettext, "Filter")}
              </.btn_basic>
            </label>
          </div>
      </div>
    </.form>
    """
  end
end
