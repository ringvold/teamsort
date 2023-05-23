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
    # TODO: Alternative layout where textarea is tall and narrow with teams on the side
    ~H"""
    <section class="form">
      <.simple_form
        for={ @form }
        phx-submit="solve"
        phx-change="change"
        as="changeset"
        autocomplete="off">

        <.button class="float-right mb-2" phx-click="fill_example">Use example data</.button>

        <.input
          field={@form[:players]}
          type="textarea"
          label="Players"
          value={ @players_raw }
          rows="10"
          cols="30"
          placeholder="Format:
name, rank
name, rank, team preference (number, 1-4)
Valid ranks: ur, s1, s2, s3, s4, se, sem, gn1, gn2, gn3, gnm, mg1, mg2, mge, dmg, le, lem, sup, glo"
        />
        <:actions>
          <.button phx-disable-with="Generating teams..">Make teams</.button>
        </:actions>
      </.simple_form>

      <!-- Teams output -->
      <section class="my-10">
        <h1 class="text-2xl font-bold dark:text-zinc-200">Teams<.button class="ml-4" phx-click="shuffle">Shuffle</.button></h1>
        <div class="my-5 flex flex-wrap flex-col md:flex-row gap-4 xl:gap-8">
          <div :for={team <- @teams} class="px-10 md:px-5 xl:px-10 py-5 flex-1 min-w-fit rounded-md dark:bg-zinc-900">
            <h3 class="text-xl font-bold dark:text-zinc-200"><%= team.name %></h3>
            <span class="py-4 font-medium dark:text-zinc-200">Score: <%= team.score %></span>
            <ol class="list-decimal list-inside">
              <li :for={player <- team.players} class="dark:text-zinc-200">
                <%= player.name %>  <%= player.team %> <%= player.rank %>
              </li>
            </ol>
          </div>
        </div>
      </section>

      <!-- History -->
      <pre
        class="dark:text-zinc-200 overflow-scroll p-5 bg-zinc-900 mb-10 rounded-md"
        >@history = <%= Jason.encode!(@players_history, pretty: true) %></pre>
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
              {:noreply, socket}
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
