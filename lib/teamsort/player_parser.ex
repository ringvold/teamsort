defmodule Teamsort.PlayerParser do
  import NimbleParsec

  alias Teamsort.Player

  comma = 44
  tab = 9
  new_line = 10

  player =
    utf8_string([{:not, comma}, {:not, tab}, {:not, new_line}], min: 1)
    |> ignore(string(" ") |> repeat() |> optional())
    |> ignore(choice([string(","), string("\t")]))
    |> ignore(string(" ") |> repeat() |> optional())
    |> utf8_string([{:not, comma}, {:not, tab}, {:not, new_line}], min: 1)
    |> ignore(string(" ") |> repeat() |> optional())
    |> ignore(string("\t") |> repeat() |> optional())
    |> ignore(string("\n") |> repeat() |> optional())
    |> reduce({:construct_player, []})

  with_team =
    utf8_string([{:not, comma}, {:not, tab}, {:not, new_line}], min: 1)
    |> ignore(string(" ") |> repeat() |> optional())
    |> ignore(choice([string(","), string("\t")]))
    |> ignore(string(" ") |> repeat() |> optional())
    |> utf8_string([{:not, comma}, {:not, tab}, {:not, new_line}], min: 1)
    |> ignore(string(" ") |> repeat() |> optional())
    |> ignore(choice([string(","), string("\t")]))
    |> ignore(string(" ") |> repeat() |> optional())
    |> integer(min: 1)
    |> ignore(string(" ") |> repeat() |> optional())
    |> ignore(string("\t") |> repeat() |> optional())
    |> ignore(string("\n") |> repeat() |> optional())
    |> reduce({:construct_player, []})

  defparsec(
    :parse,
    choice([
      with_team,
      player
    ])
    |> repeat()
  )

  defp construct_player(args) do
    case args do
      [name, rank, team] ->
        %Player{name: name, rank: rank, team: team}

      [name, rank] ->
        %Player{name: name, rank: rank}

      other ->
        dbg other
        {:error, "Could not convert #{args} to player"}
    end
  end
end
