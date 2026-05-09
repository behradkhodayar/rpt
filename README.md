# myapp

Please read on, before snapping the "use this repository" button; things are a bit
different, as this was initially created as our opiniated internal template, in
our team at [Blockzenith](https://blockzenith.bz).

The links here have a `YOUR-ORG` in them, so if you hit a broken link, make sure
to replace it first.

---

A Rust service/CLI scaffolded from
[rust-project-template](https://github.com/YOUR-ORG/rust-project-template).

## You just used this template — start here

```bash
# 1. Rename the placeholder to your project's actual name.
#    By default, uses your repo's directory name. Pass an explicit name to override.
./_setup.sh                      # or:  ./_setup.sh my-actual-name

# 2. Commit the rename.
git add -A
git commit -m "Initial setup"

# 3. Open in VS Code with the Dev Containers extension.
code .
# When prompted: "Reopen in Container". First time will pull the dev image.
```

That's it. You're now in a fully containerized Rust dev environment with
`cargo`, `clippy`, `rustfmt`, `cargo-nextest`, and `rust-analyzer` ready to go.

## Prerequisites

This template assumes you've set up the team's
[rust-dev-tooling](https://github.com/YOUR-ORG/rust-dev-tooling) on your
machine — i.e. Docker is installed and the base dev image is available
either locally (`rust-dev:stable`) or published to GHCR.

If you haven't, follow the README in that repo first.

## Project layout

```
.
├── .devcontainer/
│   └── devcontainer.json    # VS Code Dev Containers config
├── .github/
│   └── workflows/
│       ├── ci.yml           # fmt, clippy, test, audit (in the same image as dev)
│       └── docker-build.yml # production image → GHCR
├── .dockerignore
├── .gitignore
├── compose.yaml             # dev container (committed)
├── compose.override.yaml.example   # template for personal customizations
├── Dockerfile               # production multi-stage build
├── Cargo.toml
└── src/
    └── main.rs
```

## Personal customizations

Copy the example override to opt into per-developer tweaks (extra mounts,
env vars, ports, your `.gitconfig`, etc.):

```bash
cp compose.override.yaml.example compose.override.yaml
$EDITOR compose.override.yaml
```

`compose.override.yaml` is gitignored — your changes stay local. Docker
Compose merges it on top of `compose.yaml` automatically; no flags needed.

## Daily commands (inside the dev container)

| What | Command |
|---|---|
| Build | `cargo build` |
| Test | `cargo nextest run` |
| Watch + rerun tests on change | `cargo watch -x 'nextest run'` |
| Lint | `cargo clippy --all-targets --all-features` |
| Format | `cargo fmt` |
| Check for known vulns | `cargo audit` |
| Add a dep | `cargo add <crate>` |

## Building the production image

```bash
DOCKER_BUILDKIT=1 docker build -t myapp:latest .
docker run --rm myapp:latest
```

This also runs automatically in CI on push to `main` and on tagged releases,
publishing to `ghcr.io/<owner>/myapp`.

## CI

`.github/workflows/ci.yml` runs `cargo fmt --check`, `cargo clippy -D warnings`,
`cargo nextest run`, and `cargo audit` inside the same dev image you use locally.
**If it passes locally, it passes in CI** — same toolchain, same OS, same C libs.

CI pulls `ghcr.io/<repo-owner>/rust-dev:stable`. Make sure the
[rust-dev-tooling](https://github.com/YOUR-ORG/rust-dev-tooling) repo's
publish workflow has run at least once for your org before pushing this
project, otherwise CI will fail with a "manifest unknown" error.
