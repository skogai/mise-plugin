#!/bin/sh
# Runs the plugin hooks through mise in throwaway config, data, state and cache
# directories, so the result does not depend on the machine's mise setup.
set -eu

plugin_dir=$(cd "$(dirname "$0")/.." && pwd)
mise_bin=$(command -v mise)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

project="$tmp/work space"
mkdir -p "$tmp/home/.config" "$tmp/iso" "$project/bin" "$project/tools/bin" "$project/sub"

run_mise() {
    env -i HOME="$tmp/home" PATH=/usr/bin:/bin \
        MISE_CONFIG_DIR="$tmp/iso/config" MISE_SYSTEM_CONFIG_DIR="$tmp/iso/system" \
        MISE_DATA_DIR="$tmp/iso/data" MISE_STATE_DIR="$tmp/iso/state" MISE_CACHE_DIR="$tmp/iso/cache" \
        MISE_TRUSTED_CONFIG_PATHS="$tmp" MISE_EXPERIMENTAL=1 MISE_YES=1 \
        "$mise_bin" "$@"
}

failures=0
check() { # name, expected, actual
    if [ "$2" = "$3" ]; then
        echo "ok   $1"
    else
        echo "FAIL $1"
        echo "       expected: $2"
        echo "       actual:   $3"
        failures=$((failures + 1))
    fi
}

value() { # directory, variable name; prints the value mise gives a command run there
    (cd "$1" && run_mise exec -- printenv "$2") || true
}

run_mise plugins link --force skogai "$plugin_dir" >/dev/null 2>&1

# Defaults: root is the directory of the config that declares the plugin.
cat >"$project/mise.toml" <<'TOML'
[env]
_.skogai = {}
TOML
check "default root is the config root, also from a subdirectory" "$project" "$(value "$project/sub" SKOGAI_MONOREPO_DIR)"
check "default config dir" "$tmp/home/.config/skogai" "$(value "$project" SKOGAI_CONFIG_DIR)"
check "no PATH entries by default" "/usr/bin:/bin" "$(value "$project" PATH)"
check "template example variable is gone" "" "$(value "$project" SKOGAI_ENV_VAR)"

# Options: relative, ~ and absolute values; missing and repeated paths are dropped.
cat >"$project/mise.toml" <<TOML
[env]
_.skogai = { root = ".", config_dir = "~/cfg", paths = ["bin", "missing", "bin", "$project/tools/bin"] }
TOML
check "relative root" "$project" "$(value "$project" SKOGAI_MONOREPO_DIR)"
check "config_dir expands ~" "$tmp/home/cfg" "$(value "$project" SKOGAI_CONFIG_DIR)"
check "existing paths only, once, in order" "$project/bin:$project/tools/bin:/usr/bin:/bin" "$(value "$project" PATH)"

# XDG_CONFIG_HOME set by an earlier [env] entry is respected.
cat >"$project/mise.toml" <<'TOML'
[env]
XDG_CONFIG_HOME = "/xdg"
_.skogai = { root = "~/elsewhere" }
TOML
check "root expands ~" "$tmp/home/elsewhere" "$(value "$project" SKOGAI_MONOREPO_DIR)"
check "config dir follows XDG_CONFIG_HOME" "/xdg/skogai" "$(value "$project" SKOGAI_CONFIG_DIR)"

# Host defaults, and the two ways config overrides them.
case $(uname -m) in x86_64) arch=x64 ;; aarch64 | arm64) arch=arm64 ;; *) arch=$(uname -m) ;; esac
case $(uname -s) in Linux) os=linux ;; Darwin) os=macos ;; *) os=$(uname -s) ;; esac
cat >"$project/mise.toml" <<'TOML'
[env]
_.skogai = {}
TOML
check "default host" "$(uname -n)" "$(value "$project" SKOGAI_HOST)"
check "default os, in mise naming" "$os" "$(value "$project" SKOGAI_OS)"
check "default arch, in mise naming" "$arch" "$(value "$project" SKOGAI_ARCH)"

cat >"$project/mise.toml" <<'TOML'
[env]
SKOGAI_HOST = "set-above"
_.skogai = {}
SKOGAI_OS = "set-below"
TOML
check "a value set above the directive is kept" "set-above" "$(value "$project" SKOGAI_HOST)"
check "a value set below the directive wins" "set-below" "$(value "$project" SKOGAI_OS)"

cat >"$project/mise.toml" <<'TOML'
[env]
SKOGAI_HOST = ""
_.skogai = {}
TOML
check "an empty value counts as unset" "$(uname -n)" "$(value "$project" SKOGAI_HOST)"

cat >"$project/mise.toml" <<'TOML'
[env]
_.skogai = {}
TOML
cat >"$project/mise.local.toml" <<'TOML'
[env]
SKOGAI_HOST = "from-local"
TOML
check "a later config file wins" "from-local" "$(value "$project" SKOGAI_HOST)"
rm "$project/mise.local.toml"

mkdir -p "$tmp/iso/config"
cat >"$tmp/iso/config/config.toml" <<'TOML'
[env]
SKOGAI_ARCH = "from-global"
TOML
check "a value from an earlier config file is kept" "from-global" "$(value "$project" SKOGAI_ARCH)"
rm "$tmp/iso/config/config.toml"

if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed"
    exit 1
fi
echo "all checks passed"
