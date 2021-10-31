defmodule Teamsort.PlayerParserTest do
  use ExUnit.Case
  doctest Teamsort.PlayerParser

  alias Teamsort.PlayerParser
  alias Teamsort.Player

  defp parse(input), do: PlayerParser.parse(input) |> unwrap
  defp unwrap({:ok, acc, "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse " <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  test "parses one line comma separated" do
    assert parse("Player,gnm") == [%Player{name: "Player", rank: "gnm"}]
  end

  test "parses one line tab separated" do
    assert parse("Player\tgnm") == [%Player{name: "Player", rank: "gnm"}]
  end

  test "parses two lines tab and comma separated" do
    assert parse("Player\tgnm\nPlayer2,mg1") == [
             %Player{name: "Player", rank: "gnm"},
             %Player{name: "Player2", rank: "mg1"}
           ]
  end

  test "parses rank" do
    assert parse("Player\tgnm\nPlayer2\tmg2") == [
             %Player{name: "Player", rank: "gnm"},
             %Player{name: "Player2",  rank: "mg2"}
           ]
  end

  test "parses rank and team pref" do
    assert parse("""
           Player\tgnm
           Player1\tgnm\t2\t
           Player2\tmg2\t
           Player3\tgn4\t1\n\n
           Player\tgnm
           """) == [
             %Player{name: "Player", rank: "gnm"},
             %Player{name: "Player1", rank: "gnm", team: 2,},
             %Player{name: "Player2", rank: "mg2"},
             %Player{name: "Player3", rank: "gn4", team: 1},
             %Player{name: "Player", rank: "gnm"}
           ]
  end

  test "parses with space" do
    assert parse("sandesh, glo\nbna, gn2\nPlayer3\t gn4\t1") == [
             %Player{name: "sandesh", rank: "glo"},
             %Player{name: "bna", rank: "gn2"},
             %Player{name: "Player3", rank: "gn4", team: 1},
           ]

  end
end
