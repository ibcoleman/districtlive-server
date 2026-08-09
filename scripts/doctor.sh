#!/usr/bin/env bash
# Verify all prerequisites are on PATH. Reports ok/MISSING for every tool
# before exiting, so you see all gaps at once rather than fixing one at a time.
set -euo pipefail

missing=0

require() {
    local cmd="$1" hint="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "ok       $cmd"
    else
        echo "MISSING  $cmd  ($hint)"
        missing=1
    fi
}

warn() {
    local cmd="$1" hint="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "ok       $cmd"
    else
        echo "warn     $cmd  ($hint)"
    fi
}

require bazel      "install bazelisk: brew install bazelisk or https://github.com/bazelbuild/bazelisk"
require kind       "install kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
require kubectl    "install kubectl: https://kubernetes.io/docs/tasks/tools/"
require tilt       "install tilt: https://docs.tilt.dev/install.html"
require pnpm       "install pnpm: npm install -g pnpm"
require docker     "install Docker Engine or Docker Desktop"
require sqlx       "cargo install sqlx-cli --no-default-features --features postgres"

warn rust-analyzer "rustup component add rust-analyzer"

if ! docker compose version >/dev/null 2>&1; then
    echo "MISSING  docker compose plugin  (install Docker Desktop or the compose plugin)"
    missing=1
else
    echo "ok       docker compose"
fi

if [ "${ENABLE_LSP_TOOL:-}" != "1" ]; then
    echo "warn     ENABLE_LSP_TOOL not set to 1 (export from shell rc or devcontainer remoteEnv — see CLAUDE.md)"
else
    echo "ok       ENABLE_LSP_TOOL"
fi

# Validate pnpm-workspace.yaml is well-formed (no placeholders, required keys present).
pnpm_ws="pnpm-workspace.yaml"
if [ ! -f "$pnpm_ws" ]; then
    echo "MISSING  $pnpm_ws  (required for pnpm/Bazel builds)"
    missing=1
else
    pnpm_ok=1

    # Reject lines that look like instruction placeholders rather than real values.
    # Matches patterns like: "set this to", <placeholder>, {{mustache}}, TODO, FIXME.
    if grep -Eiq '(set this to|<[^>]+>|\{\{[^}]+\}\}|TODO|FIXME)' "$pnpm_ws"; then
        echo "MISSING  $pnpm_ws: contains placeholder text — check for unset template values"
        missing=1
        pnpm_ok=0
    fi

    # Require allowBuilds section (pnpm v11+).
    if ! grep -q '^allowBuilds:' "$pnpm_ws"; then
        echo "MISSING  $pnpm_ws: missing 'allowBuilds:' key (required for pnpm v11)"
        missing=1
        pnpm_ok=0
    fi

    # Require onlyBuiltDependencies section (aspect_rules_js / Bazel).
    if ! grep -q '^onlyBuiltDependencies:' "$pnpm_ws"; then
        echo "MISSING  $pnpm_ws: missing 'onlyBuiltDependencies:' key (required for Bazel / aspect_rules_js)"
        missing=1
        pnpm_ok=0
    fi

    if [ "$pnpm_ok" -eq 1 ]; then
        echo "ok       $pnpm_ws"
    fi
fi

if [ "$missing" -ne 0 ]; then
    echo ""
    echo "FAIL: one or more required tools are missing"
    exit 1
fi

echo ""
echo "doctor: OK"
