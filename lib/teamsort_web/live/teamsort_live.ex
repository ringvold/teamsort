defmodule TeamsortWeb.TeamsortLive do
  use TeamsortWeb, :live_view

  alias Teamsort.Solver
  alias Teamsort.Player
  alias Teamsort.PlayerParser

  import Ecto.Changeset

  alias TeamsortWeb.PlayersForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(:players, [])
      |> assign(:players_raw, "")
      |> assign(:teams, [])
      |> assign(:players_history, [])
      |> assign_form(%Ecto.Changeset{data: %PlayersForm{}})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="form">
      <.simple_form
        for={ @form }
        phx-submit="solve"
        phx-change="change"
        as="changeset"
        autocomplete="off">

        <.button phx-click="fill_example">Use example data</.button>

        <.input
          field={@form[:players]}
          type="textarea"
          label="Players"
          value={ @players_raw }
          rows="10"
          placeholder="Format:\nname, rank\nname, team preference (number), rank\n
    Valid ranks: ur, s1, s2, s3, s4, se, sem, gn1, gn2, gn3, gnm, mg1, mg2, mge, dmg, le, lem, sup, glo"
        />
        <:actions>
          <.button phx-disable-with="Generating teams..">Make teams</.button>
        </:actions>
      </.simple_form>

      <!-- Teams output -->
      <section class="my-10">
        <h1 class="text-2xl font-bold">Teams</h1>
        <div class="block"><.button phx-click="shuffle">Shuffle</.button></div>
        <div class="my-5 flex flex-wrap gap-4 md:gap-8 xl:gap-28">
          <div :for={team <- @teams} class="">
            <h3 class="text-xl font-bold"><%= team.name %></h3>
            <span class="py-4 font-medium">Score: <%= team.score %></span>
            <ol class="list-decimal list-inside">
              <li :for={player <- team.players}>
                <%= player.name %>  <%= player.team %> <%= player.rank %>
              </li>
            </ol>
          </div>
        </div>
      </section>

      <!-- History -->
      <pre>@history = <%= Jason.encode!(@players_history, pretty: true) %></pre>
    </section>
    """
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:players])
    |> validate_required([:players])
  end

  # TODO: Make async, better error handling?
  @impl true
  def handle_event("change", %{"players_form" => form}, socket) do
    cset = changeset(%PlayersForm{}, form)

    case cset.valid? do
      true ->
        case parse_players(get_field(cset, :players)) do
          {:ok, players} ->
            {:noreply,
              socket
              |> assign(
               players: players,
               players_raw: get_field(cset, :players)
             )
             |> assign_form(cset)}

          {:error, _error} ->
            {:noreply,
              socket
                |> put_flash(:error, "Invalid input")
                |> assign_form(add_error(cset, :players, "invalid input"))}
        end

      false ->
        {:noreply,
          socket
          |> assign_form(cset)
        }
    end
  end

  # TODO: Make async
  @impl true
  def handle_event("solve", %{"players_form" => form}, socket) do
    cset = changeset(%PlayersForm{}, form)

    if cset.valid? do
      case parse_players(get_field(cset, :players)) do
        {:ok, []} ->
          {:noreply,
            socket
              |> put_flash(:error, "could not be parsed")
              |> assign_form(add_error(cset, :players, "could not be parsed"))
          }

        {:ok, players} ->
          case Solver.solve(players) do
            {:ok, teams} ->
              {:noreply, assign(socket, teams: teams)}

            {:error, _error} ->
              {:noreply,
                socket
                  |> put_flash(:error, "Could not create teams")
                  |> assign_form(add_error(cset, :players, "could not create teams"))
                  |> Map.put(:action, :validate)
              }
          end

          # {:ok, teams} = Solver.solve(players)
          # {:noreply, assign(socket, teams: teams)}

        {:error, _message} ->
          {:noreply, socket
              |> put_flash(:error, "Could not parse player")
              |> assign_form(add_error(cset, :players,"could not be parsed"))
           }
      end
    else
      {:noreply, socket}
    end
  end

  # TODO: Make async
  @impl true
  def handle_event("shuffle", _value, socket) do
    shuffled =
      socket.assigns.players_raw |> String.split("\n") |> Enum.shuffle() |> Enum.join("\n")

    if shuffled != "" do
      updated_socket = update(socket, :players_history, &[shuffled | &1])

      case parse_players(shuffled) do
        {:ok, players} ->
          case Solver.solve(players) do
            {:ok, teams} ->
              {:noreply, assign(updated_socket, players_raw: shuffled, teams: teams)}

            {:error, :unexpected} ->
          {:noreply, assign(updated_socket, players_raw: shuffled)}
        end

        {:error, _error} ->
          {:noreply,
            socket
              |> assign_form(add_error(socket.assigns.changeset, :players,"could not be parsed"))
          }
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("fill_example", _value, socket) do
    {:noreply,
     assign(socket,
       players_raw: """
       antorn3dthe7th\ts2\t0
       bna-cooky\ts3\t0
       Buððah\tgn2\t0
       Dinogutten\ts2\t0
       eask64\tmg2\t0
       l0lpalme\tmg1\t1
       Madde\tmg1\t1
       McDuckian\tmg1\t0
       Miksern\tgn3\t0
       Pokelot\tle\t0
       SchousKanser\ts2\t0
       Steffe\tmg1\t0
       Ditlesen\tsup\t0
       Jessie Maye\tse\t1
       Igorrr\tdmg\t0
       HVaade\tmge\t0
       """
     )}
  end

  @spec parse_players(any) :: {:ok, [Player]} | {:error, String.t()}
  def parse_players(value) do
    try do
      value
      |> PlayerParser.parse()
      |> unwrap
    rescue
      e in RuntimeError ->
        IO.puts("ERROR")
        IO.puts(e)
        {:error, "Could not parse players. Got #{e}"}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp unwrap({:ok, players, "", _, _, _}), do: {:ok, players}
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse " <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}
end
