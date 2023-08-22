defmodule TeamsortWeb.TeamsortLive do
  use TeamsortWeb, :live_view

  alias Teamsort.Solver
  alias Teamsort.Player
  alias Teamsort.PlayerParser

  import Ecto.Changeset

  alias TeamsortWeb.PlayersForm

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:players, [])
     |> assign(:players_raw, "")
     |> assign(:teams, [])
     |> assign(:players_history, [])
     |> assign(:solving, false)
     |> assign_form(%Ecto.Changeset{data: %PlayersForm{}})}
  end

  @impl true
  def render(assigns) do
    # TODO: Alternative layout where textarea is tall and narrow with teams on the side
    ~H"""
    <section class="form">
      <.simple_form for={@form} phx-submit="solve" phx-change="change" autocomplete="off">
        <.button class="float-right mb-2" phx-click="fill_example">Use example data</.button>

        <.input
          field={@form[:players]}
          type="textarea"
          label="Players"
          value={@players_raw}
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
      <!--
        Teams output
      -->
      <section class="my-10">
        <h1 class="text-2xl font-bold dark:text-zinc-200">
          Teams<.button class="ml-4" phx-click="shuffle" phx-disable-with="Shuffling..">
            Shuffle
          </.button>
        </h1>

        <div class="my-5 flex flex-wrap flex-col md:flex-row gap-4 xl:gap-8">
          <%= if @solving do %>
            <h1 class="text-xl dark:text-zinc-200 p-5 bg-zinc-900 mb-10 rounded-md min-w-fit">
              Generating teams..
            </h1>
          <% else %>
            <%= if @teams != [] do %>
              <div
                :for={team <- @teams}
                class="px-10 md:px-5 xl:px-10 py-5 flex-1 min-w-fit rounded-md dark:bg-zinc-900"
              >
                <h3 class="text-xl font-bold dark:text-zinc-200"><%= team.name %></h3>
                <span class="py-4 font-medium dark:text-zinc-200">Score: <%= team.score %></span>
                <ol class="list-decimal list-inside">
                  <li :for={player <- team.players} class="dark:text-zinc-200">
                    <%= player.name %> <%= player.team %> <%= player.rank %>
                  </li>
                </ol>
              </div>
            <% else %>
              <p class="text-lg dark:text-zinc-200 p-5 bg-zinc-900 mb-10 rounded-md">
                Generated teams will be displayed here :)
              </p>
            <% end %>
          <% end %>
        </div>
      </section>
      <!--
        History
      -->
      <pre class="dark:text-zinc-200 overflow-scroll p-5 bg-zinc-900 mb-10 rounded-md">@history = <%= Jason.encode!(@players_history, pretty: true) %></pre>
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
            dbg _error
            changeset =
              add_error(cset, :players, "invalid input")
              |> Map.put(:action, :validate)
              |> dbg

            {:noreply,
             socket
             |> assign_form(changeset)}
        end

      false ->
        {:noreply,
         socket
         |> assign_form(cset)}
    end
  end

  # TODO: Make async
  @impl true
  def handle_event("solve", %{"players_form" => form}, socket) do
    cset = changeset(%PlayersForm{}, form)
    send(self(), {:solve, cset})

    {:noreply,
     socket
     |> assign(:solving, true)}
  end

  def handle_info({:solve, cset}, socket) do
    if cset.valid? do
      case parse_players(get_field(cset, :players)) do
        {:ok, []} ->
          {:noreply,
           socket
           |> put_flash(:error, "could not be parsed")
           |> assign_form(add_error(cset, :players, "could not be parsed"))
           |> assign(:solving, false)}

        {:ok, players} ->
          case Solver.solve(players) do
            {:ok, teams} ->
              {:noreply,
               socket
               |> assign(teams: teams)
               |> assign(:solving, false)}

            {:error, error} ->
              changeset =
                if String.contains?(error, [
                     "Error: type error: undefined identifier",
                     "did you mean"
                   ]) do
                  err =
                    String.replace_leading(error, "Error: type error: undefined identifier", "")
                    |> String.split("\n")
                    |> List.first()
                    |> dbg

                  add_error(cset, :players, "invalid input. Unknown rank #{err}")
                  |> Map.put(:action, :validate)
                else
                  add_error(cset, :players, "invalid input")
                  |> Map.put(:action, :validate)
                end

              {:noreply,
               socket
               |> assign_form(changeset)
               |> assign(:solving, false)}
          end

        {:error, message} ->
          dbg(message)

          changeset =
            add_error(cset, :players, "could not be parsed")
            |> Map.put(:action, :validate)

          {:noreply,
           socket
           |> put_flash(:error, "Could not parse player")
           |> assign_form(changeset)
           |> assign(:solving, false)}
      end
    else
      {:noreply,
       socket
       |> assign(:solving, false)}
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

            {:error, msg} ->
              # TODO: extract type errors: {:error, "Error: type error: undefined identifier `mgg1', did you mean `mg1'?\n/private/var/folders/m3/v1_2c_1s3sbg1gt0_srtvq4r0000gn/T/tmp.scexpBMgU4.mzn:60.39-42\n"
              {:noreply, socket |> put_flash(:error, msg)}
          end

        {:error, _error} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not parse shuffled players")}
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
        dbg(e)
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
