defmodule TeamsortWeb.Components.Teamsort do
  use Surface.LiveComponent

  alias Teamsort.Solver
  alias Teamsort.Player
  alias Teamsort.PlayerParser

  import Ecto.Changeset

  alias Surface.Components.Form.TextArea
  alias Surface.Components.Form.Label
  alias Surface.Components.Form.ErrorTag
  alias Surface.Components.Form.Field
  alias Surface.Components.Form

  alias TeamsortWeb.PlayersForm

  data(players, :list, default: [])
  data(players_raw, :string, default: "")
  data(teams, :list, default: [])
  data(players_history, :list, default: [])
  data(changeset, :changeset, default: %Ecto.Changeset{data: %PlayersForm{}})

  def render(assigns) do
    ~F"""
    <!-- Form -->
    <section class="form">
      <Form for={ @changeset } submit="solve" change="change" opts={ as: "changeset", autocomplete: "off" }>
        <Field class="field" name={ :players }>
          <Label class="label">Players <button class="button is-small" :on-capture-click="fill_example">Use example data</button></Label>
          <TextArea
            class="textarea"
            rows="10"
            value={ @players_raw }
            opts={ placeholder: "Format:\nname, rank (1-18)\nname, rank name, rank\nname, rank name, team preference (number), rank"}
            ></TextArea>
          <ErrorTag />
        </Field>
        <div class="field">
          <div class="control">
            <button class="button id-primary" phx-disable-with="Generating teams.." >Make teams</button>
          </div>
        </div>
      </Form>

      <!-- Teams output -->
      <section class="section">
        <h1 class="title">Teams</h1>
        <div class="block"><button class="button" :on-click="shuffle">Shuffle</button></div>
        <div class="columns">
          <div class="column" :for={ team <- @teams } >
            <div class="box content">
              <h3 class="is-size-4">{ team.name }</h3>
              <span class="block">Score: { team.score }</span>
              <ol>
                <li :for={ player <- team.players }>
                  { player.name } { player.rank_name } { player.team } { player.rank }
                </li>
              </ol>
            </div>
          </div>
        </div>
      </section>

      <!-- History -->
      <pre>@history = { Jason.encode!(@players_history, pretty: true) }</pre>
    </section>
    """
  end

  defp changeset(changeset, attrs) do
    changeset
      |> cast(attrs, [:players])
      |> validate_required([:players])
  end

  def handle_event("change", %{ "changeset" => form }, socket) do
    cset = changeset(%PlayersForm{}, form)

    case cset.valid? do
      true ->
        case parse_players(get_field(cset, :players)) do
          {:ok, players} ->
            {:noreply,
            assign(socket,
              players: players,
              players_raw: get_field(cset, :players),
              changeset: cset
            )}

          {:error, _error} ->
            {:noreply,
              assign(socket,
                changeset: add_error(cset, :players, "invalid input")
              )}
        end


      false ->
         {:noreply,
            assign(socket,
              changeset: cset
            )}
    end
  end

  def handle_event("shuffle", _value, socket) do
    shuffled =
      socket.assigns.players_raw |> String.split("\n") |> Enum.shuffle() |> Enum.join("\n")

    updated_socket = update(socket, :players_history, &[shuffled | &1])

    if shuffled != "" do
      case parse_players(shuffled) do
        {:ok, players} ->
          teams = Solver.solve(players)
          {:noreply, assign(updated_socket, players_raw: shuffled, teams: teams)}

        {:error, _error} ->
          {:noreply,
              assign(socket,
                changeset: add_error(socket.assigns.changeset, :players, "could not be parsed")
              )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("solve", %{ "changeset" => form }, socket) do
    cset = changeset(%PlayersForm{}, form)
    if cset.valid? do
      case parse_players(get_field(cset,:players)) do
        {:ok, [] } ->
          {:noreply,
            assign(socket,
                changeset: add_error(socket.assigns.changeset, :players, "could not be parsed")
              )
          }

        {:ok, players } ->
          teams = Solver.solve(players)
          {:noreply, assign(socket, teams: teams)}

        {:error, _message} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("fill_example", _value, socket) do
    {:noreply,
     assign(socket,
       players_raw: """
       antorn3dthe7th\ts2.\t0\t2
       bna-cooky\ts3.\t0\t3
       Buððah\tgn2.\t0\t8
       Dinogutten\ts2.\t0\t2
       eask64\tmg2.\t0\t12
       l0lpalme\tmg1.\t1\t11
       Madde\tmg1.\t1\t11
       McDuckian\tmg1.\t0\t11
       Miksern\tgn3.\t0\t9
       Pokelot\tle\t0\t15
       SchousKanser\ts2.\t0\t2
       Steffe\tmg1.\t0\t11
       Ditlesen\tsup\t0\t17
       Jessie Maye\tse\t1\t5
       Igorrr\tdmg\t0\t14
       HVaade\tmge\t0\t13
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

  defp unwrap({:ok, players, "", _, _, _}), do: {:ok, players }
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse " <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

end
