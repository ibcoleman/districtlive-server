#!/usr/bin/env bash
set -euo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN"

# bazelisk (as 'bazel')
curl -fsSL -o "$BIN/bazel" \
  https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
chmod +x "$BIN/bazel"

# just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
  | bash -s -- --to "$BIN"

# kind
curl -fsSL -o "$BIN/kind" \
  https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x "$BIN/kind"

# kubectl
KUBECTL_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL -o "$BIN/kubectl" \
  "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
chmod +x "$BIN/kubectl"

# tilt
TILT_TAG=$(curl -fsSL https://api.github.com/repos/tilt-dev/tilt/releases/latest | jq -r .tag_name)
TILT_VER="${TILT_TAG#v}"
curl -fsSL "https://github.com/tilt-dev/tilt/releases/download/${TILT_TAG}/tilt.${TILT_VER}.linux.x86_64.tar.gz" \
  | tar -xzC "$BIN" tilt

# jj (Jujutsu VCS)
JJ_TAG=$(curl -fsSL https://api.github.com/repos/jj-vcs/jj/releases/latest | jq -r .tag_name)
JJ_TMP=$(mktemp -d)
curl -fsSL "https://github.com/jj-vcs/jj/releases/download/${JJ_TAG}/jj-${JJ_TAG}-x86_64-unknown-linux-musl.tar.gz" \
  | tar -xzC "$JJ_TMP"
find "$JJ_TMP" -name jj -type f -executable -exec mv {} "$BIN/jj" \;
chmod +x "$BIN/jj"
rm -rf "$JJ_TMP"

# pnpm (the official node feature configures npm prefix so -g installs to user dir)
npm install -g pnpm

# Rust toolchain components
rustup component add rust-analyzer clippy rustfmt
