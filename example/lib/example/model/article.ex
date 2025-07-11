defmodule Example.Model.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: true
  end
end
