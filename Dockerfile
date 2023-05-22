######
### Fist Stage - Building the Release
###
FROM hexpm/elixir:1.14.4-erlang-25.3-alpine-3.18.0 AS build

# install build dependencies
RUN apk add --no-cache build-base npm

# prepare build dir
WORKDIR /app

# extend hex timeout, SHELL needs to be set to start the app
ENV HEX_HTTP_TIMEOUT=20 \
    SHELL=/bin/bash HOST_NAME=localhost

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV as prod
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey

# Copy over the mix.exs and mix.lock files to load the dependencies. If those
# files don't change, then we don't keep re-fetching and rebuilding the deps.
COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod && \
    mix deps.compile

COPY priv priv
COPY assets assets

# NOTE: If using TailwindCSS, it uses a special "purge" step and that requires
# the code in `lib` to see what is being used. Uncomment that here before
# running the npm deploy script if that's the case.
# COPY lib lib

# build assets
RUN mix assets.deploy
RUN mix phx.digest

# copy source here if not using TailwindCSS
COPY lib lib

# compile and build release
COPY rel rel
RUN mix do compile, release


###
### Second Stage - Setup the Runtime Environment
###

FROM minizinc/minizinc:latest-alpine AS minizinc


# prepare release docker image
FROM alpine:3.13.3 AS app
RUN apk add --no-cache openssl ncurses-libs libc6-compat libstdc++

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody


COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/teamsort ./

COPY --from=minizinc /usr/local/bin/minizinc /usr/local/bin/minizinc
COPY --from=minizinc /usr/local/share/minizinc /usr/local/share/minizinc

ENV HOME=/app
ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=nokey
ENV PORT=4000
ENV SHELL=/bin/sh HOST_NAME=localhost

CMD ["bin/teamsort", "start"]
