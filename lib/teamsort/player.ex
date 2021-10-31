defmodule Teamsort.Player do
  @derive Jason.Encoder
  @enforce_keys [:name, :rank]
  defstruct [:name, :rank, team: 0]

  def to_string(player) do
    Map.to_list(player)
    |> Enum.reduce("", fn {key, value}, acc ->
      if key == :__struct__ do
        acc
      else
        "#{acc},#{Atom.to_string(key)}, #{value}"
      end
    end)
  end

  def rank_to_num(rank) do
    case rank do
      "ur" -> 1
      "s1" -> 2
      "s2" -> 3
      "s3" -> 4
      "s4" -> 5
      "se" -> 6
      "sem" -> 7
      "gn1" -> 8
      "gn2" -> 9
      "gn3" -> 10
      "gnm" -> 11
      "mg1" -> 12
      "mg2" -> 13
      "mge" -> 14
      "dmg" -> 15
      "le" -> 16
      "lem" -> 17
      "sup" -> 18
      "glo" -> 19
    end
  end
end
