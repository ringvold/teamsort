defmodule TeamsortWeb.PlayersForm do
  use Ecto.Schema

  embedded_schema do
    field :players, :string, default: ""
  end
end
