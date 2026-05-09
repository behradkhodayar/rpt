# syntax=docker/dockerfile:1.7
#
# Production image — multi-stage build with cargo-chef for proper layer caching.
#
# Build:  DOCKER_BUILDKIT=1 docker build -t myapp:latest .
# Run:    docker run --rm myapp:latest
#
# Replace `myapp` everywhere with your actual binary name (the [[bin]] name
# from Cargo.toml, or your package name if it's a single-binary crate).

# =============================================================================
# Stage 1: chef base — install cargo-chef
# =============================================================================
# We use the same Debian Bookworm slim base as the dev image, so dev and prod
# stay on the same glibc / OpenSSL versions.
FROM rust:1-slim-bookworm AS chef
WORKDIR /app
RUN cargo install cargo-chef --locked

# =============================================================================
# Stage 2: planner — produce a recipe.json describing the dependency graph
# =============================================================================
# This stage just inspects Cargo.toml/Cargo.lock and emits a recipe.
# It re-runs whenever any source file changes, but it's cheap.
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# =============================================================================
# Stage 3: builder — compile dependencies, then the app
# =============================================================================
FROM chef AS builder

# System libs needed at COMPILE time (e.g. OpenSSL headers).
# These don't end up in the final image — that's the whole point of multi-stage.
RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy ONLY the recipe first. This layer is cached as long as your dep graph
# doesn't change — meaning ordinary source edits don't trigger a full rebuild.
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# Now copy the actual source and build the app.
# Because deps are already compiled, this step only rebuilds your own code.
COPY . .
RUN cargo build --release --bin myapp

# =============================================================================
# Stage 4: runtime — minimal image, just the binary
# =============================================================================
# debian:bookworm-slim is ~80 MB and gives us a normal libc/openssl runtime.
# If your binary is statically linked or doesn't need TLS roots, you can
# replace this with `gcr.io/distroless/cc-debian12` (~20 MB) or even `scratch`
# with a musl build.
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        # Add other RUNTIME shared libs your app needs here.
        # Common examples: libssl3 (if not statically linked), libpq5 (Postgres).
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash --uid 1001 app

COPY --from=builder /app/target/release/myapp /usr/local/bin/myapp

USER app
WORKDIR /home/app

# If your app is a server, document its port (this is metadata only —
# you still need `-p 8080:8080` when running it).
# EXPOSE 8080

ENTRYPOINT ["myapp"]
