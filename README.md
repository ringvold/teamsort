# Teamsort

Teamsort is a web application that generates teams for CSGO based on a list of 
players with ranks. See usage with example data on teamsort.fly.dev.

Teamsort uses a [Minizinc] model and a solver ([CBC]) to find the most balanced 
teams based on the players ranks.

[Minizinc]: https://www.minizinc.org
[CBC]: https://github.com/coin-or/Cbc


### Runnig Teamsort

Start app with docker: `docker run -p 4000:4000 -e FLY_APP_NAME=teamsort -e SECRET_KEY_BASE=put-a-64-bytes-long-string-here ghcr.io/ringvold/teamsort`

Go to http://localhost:4000

**Note:** 
- `FLY_APP_NAME` is required for now as the images is made for Fly.io, but this 
can be changed in the future to not be required.
- `SECRET_KEY_BASE` need to be at least 64 bytes long or Phoenix will complain 
  and the app will not start. This is a requirement of Phoenix. [Because security](https://elixirforum.com/t/can-someone-explain-config-prod-secret-exs-to-me/3810/2).


The application can be run normaly with `mix phx.server` or as a elixir release 
but the correct minizinc and cbc setup can be hard to get right so the docker 
image is recommended.

### Minizinc model

The Minizinc model can be found in [priv/model.mzn]().

The model is heavily based on [this answer on StackOverflow](https://stackoverflow.com/a/53365524) by 
Axel Kemper. Thanks to him for the initial solution and to my colleague 
Jørgen Granseth for finding it and making modifications to fit this use case. 🙇‍♂️
