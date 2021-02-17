FROM bitwalker/alpine-elixir-phoenix:latest AS phx-builder

# Set exposed ports
ENV MIX_ENV=prod APP_NAME=teamsort

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Same with npm deps
ADD assets/package.json assets/
RUN cd assets && \
    npm install

ADD . .

ARG KEY_BASE
ENV SECRET_KEY_BASE=$KEY_BASE

# Run frontend build, compile, and digest assets
RUN cd assets/ && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest


RUN mix release

FROM minizinc/minizinc:latest-alpine AS minizinc

FROM bitwalker/alpine-elixir:latest
LABEL org.opencontainers.image.source https://github.com/ringvold/teamsort

EXPOSE 4000 443
ENV PORT=4000 MIX_ENV=prod
ARG KEY_BASE
ENV SECRET_KEY_BASE=$KEY_BASE APP_NAME=teamsort \
    SHELL=/bin/bash HOST_NAME=localhost

RUN apk add --update libc6-compat libstdc++

COPY --from=phx-builder /opt/app/_build /opt/app/_build

COPY --from=minizinc /usr/local/bin/minizinc /usr/local/bin/minizinc
COPY --from=minizinc /usr/local/share/minizinc /usr/local/share/minizinc

RUN chown -R default /opt/app/
# alternatively you can just copy the whole dir over with:
# COPY --from=phx-builder /opt/app /opt/app
# be warned, this will however copy over non-build files

USER default

CMD ["_build/prod/rel/teamsort/bin/teamsort", "start"]