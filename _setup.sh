#!/usr/bin/env bash
# _setup.sh — one-time post-template-clone setup.
#
# Run this AFTER you've used "Use this template" on rust-project-template
# and cloned your new repo locally. It substitutes the placeholder name
# `myapp` for your actual project name across:
#   - Cargo.toml
#   - Dockerfile
#   - README.md
#
# Then it self-deletes. You should commit the result.
#
# Usage:
#   ./_setup.sh                # uses current directory name as the project name
#   ./_setup.sh my-project     # uses an explicit name

set -euo pipefail

if [[ $# -lt 1 ]]; then
    PROJECT_NAME="$(basename "$(pwd)")"
    echo "No name given; using directory name: $PROJECT_NAME"
else
    PROJECT_NAME="$1"
fi

# Cargo crate names: lowercase letters, digits, underscore, or hyphen,
# starting with a letter. (Underscores and hyphens are interchangeable
# in some contexts, but the package name itself is what we set here.)
if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    echo "Error: '$PROJECT_NAME' isn't a valid cargo crate name." >&2
    echo "Use lowercase letters, digits, underscore, or hyphen, starting with a letter." >&2
    exit 1
fi

PLACEHOLDER="myapp"

if [[ "$PROJECT_NAME" == "$PLACEHOLDER" ]]; then
    echo "Project name is already '$PLACEHOLDER' — nothing to do."
    exit 0
fi

echo "==> Substituting '$PLACEHOLDER' → '$PROJECT_NAME' in: Cargo.toml, Dockerfile, README.md, src/main.rs"

# \b is a GNU sed word boundary — Linux-only, which is fine since
# this template is Linux-first.
sed -i "s/\b${PLACEHOLDER}\b/${PROJECT_NAME}/g" \
    Cargo.toml \
    Dockerfile \
    README.md \
    src/main.rs

# Self-delete
echo "==> Removing _setup.sh (self-delete)"
rm -- "$0"

cat <<EOF

Done. Recommended next steps:
  git add -A
  git commit -m "Initial setup as $PROJECT_NAME"
  code .              # then 'Reopen in Container'

Or, without VS Code:
  docker compose up -d
  docker compose exec dev bash
EOF
