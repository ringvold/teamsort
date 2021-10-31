enum Rank = { ur, s1, s2, s3, s4, se, sem, gn1, gn2, gn3, gnm, mg1, mg2, mge, dmg, le, lem, sup, glo };

% Avoid recursive definition between noOfPlayers and rank
% by defining the inputs in an array of unspecified size.
array[int] of Rank: playerRanks;
% array[Players] of string: players;
array[Players] of var {0} union Teams: preference;


int: maxPlayersPerTeam = 5;
int: minPlayersPerTeam = 4;
int: noOfTeams = ceil(noOfPlayers / maxPlayersPerTeam);
int: noOfPlayers = length(playerRanks);
set of int: Players = 1..noOfPlayers;
set of int: Teams = 1..noOfTeams;
array[Players] of int: rank = playerRanks;
array[Players] of var 1..noOfTeams: team;


array[Teams] of var int: score;

set of int: TeamSize = 4..5;
array[Teams] of var TeamSize: teamSize;

constraint forall(t in Teams) (
    teamSize[t] = sum([team[p] == t | p in Players])
);

%  same number of players per team
constraint forall(t in Teams) (
    maxPlayersPerTeam >= sum([team[p] == t | p in Players])
);

% enforce preference
constraint forall(p in Players) (
    if preference[p] > 0 then team[p] == preference[p] else true endif
);

%  sum up the ELO numbers per team
constraint forall(t in Teams) (
    score[t] == sum([if team[p] == t then rank[p] else 0 endif | p in Players])
);

%  enforce sorted sums to break symmetries
%  and avoid minimum/maximum predicates
constraint forall(t1 in Teams, t2 in Teams where t1 < t2) (
    score[t1] <= score[t2]
);

% Symmetry breaking constraint => last team - first team = greates diff
solve minimize score[noOfTeams] - score[1];
%output outputJSON();
