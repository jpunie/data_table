defmodule DataTable.Theme.Util do
  @moduledoc """
  Utilities which are useful for building your own theme.
  """

  import Phoenix.Component

  def generate_pages(page, page_size, total_results, with_ellipsis \\ false) do
    max_page = div(total_results + (page_size - 1), page_size) - 1

    middle_pages =
      (page - 3)..(page + 3)
      |> Enum.filter(&(&1 >= 0))
      |> Enum.filter(&(&1 <= max_page))

    resolve_pages(page, middle_pages, max_page, with_ellipsis)
  end

  def resolve_pages(page, middle_pages, max_page, with_ellipsis) do
    pages = Enum.map(middle_pages, &{:page, &1, &1 == page})

    if with_ellipsis do
      pages
      |> maybe_prepend_ellipsis(middle_pages)
      |> maybe_prepend_first_page(middle_pages, page)
      |> maybe_append_ellipsis(middle_pages, max_page)
      |> maybe_append_last_page(middle_pages, page, max_page)
    else
      pages
    end
  end

  defp maybe_prepend_ellipsis(pages, middle_pages) do
    if Enum.min(middle_pages) > 1, do: [{:ellipsis, nil, nil} | pages], else: pages
  end

  defp maybe_prepend_first_page(pages, middle_pages, page) do
    if 0 not in middle_pages, do: [{:page, 0, page == 0} | pages], else: pages
  end

  defp maybe_append_ellipsis(pages, middle_pages, max_page) do
    if Enum.max(middle_pages) < max_page - 1, do: pages ++ [{:ellipsis, nil, nil}], else: pages
  end

  defp maybe_append_last_page(pages, middle_pages, page, max_page) do
    if max_page not in middle_pages,
      do: pages ++ [{:page, max_page, page == max_page}],
      else: pages
  end

  def render_pages(assigns) do
    ~H"""
    <%= for {type, page_num, current} <- generate_pages(@page, @page_size, @total_results, true) do %>
      <%= if type == :page do %>
                <a
                  phx-click="change-page"
                  phx-target={@target}
                  phx-value-page={page_num}
                  class={[
                    (
                      if current, do: "inline-flex items-center justify-center leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300",
                        else: "inline-flex items-center justify-center leading-5 px-3.5 py-2 border border-gray-200 dark:border-gray-700 bg-white text-gray-600 hover:bg-gray-50 hover:text-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-400"
                    )
                  ]}>
                  <%= page_num + 1 %>
                </a>
      <% end %>
      <%= if type == :ellipsis do %>
          <span class="inline-flex items-center justify-center px-4 py-2 border border-gray-200 dark:border-gray-700 bg-white text-gray-600 dark:bg-gray-900 dark:text-gray-400">
            ...
          </span>
      <% end %>
    <% end %>
    """
  end
end
