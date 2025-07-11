defmodule Example.Repo.Migrations.AddPublishedFlag do
  use Ecto.Migration

  def change do
    alter table("articles") do
      add :published, :boolean, default: false
    end
  end
end
