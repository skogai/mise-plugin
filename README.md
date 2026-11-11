# skogai mise plugin

A [mise](https://mise.jdx.dev) environment plugin that gives a SkogAI workspace its base environment variables and PATH entries.

## Use

Declare the plugin and activate it under `[env]`:

```toml
[plugins]
skogai = "https://github.com/skogai/mise-plugin"

[env]
_.skogai = { paths = ["bin"] }
```

mise installs the plugin from the URL the first time the config is loaded.

## What it sets

| Variable | Value |
|---|---|
| `SKOGAI_MONOREPO_DIR` | The workspace root. |
| `SKOGAI_CONFIG_DIR` | The SkogAI config directory. |

It prepends each directory in `paths` to `PATH`. With no `paths`, `PATH` is left alone.

## Options

| Option | Default | Meaning |
|---|---|---|
| `root` | Directory of the config file that declares the plugin | Workspace root. |
| `config_dir` | `$XDG_CONFIG_HOME/skogai`, or `~/.config/skogai` | SkogAI config directory. Relative values resolve against `root`. |
| `paths` | none | Directories to prepend to `PATH`. Relative values resolve against `root`. Directories that do not exist are skipped, and a directory listed twice is added once. |

A leading `~` is expanded to `$HOME`. Absolute paths are used as written. A relative `root` resolves against the directory of the declaring config file, not the current directory, so the values are the same from any subdirectory.

The hooks only compute values. They do not download, write files, or run commands.

## Layout

```
├── metadata.lua       # Plugin name and version
├── hooks/
│   ├── mise_env.lua   # Environment variables
│   └── mise_path.lua  # PATH entries
├── lib/skogai.lua     # Option handling shared by both hooks
├── test/run.sh        # Hook checks
├── types/             # LuaCATS definitions for the mise plugin API
└── hk.pkl             # Lint configuration
```

## Development

```bash
mise install       # development tools
mise run lint      # stylua, lua-language-server, actionlint over all files
mise run lint-fix
mise run test
```

`mise run test` links this checkout as the plugin inside temporary mise config, data, state, and cache directories, then checks the variables and `PATH` that mise produces. It needs `mise` on `PATH` and does not read or change the machine's mise setup.

To try a checkout in another project, link it under a second name and use that name in the directive:

```bash
mise plugins link --force skogai-develop /path/to/mise-plugin
```

A link belongs to the mise data directory, not to a project. Every project on the machine that uses `skogai-develop` gets the checkout linked last.

Requires mise 2026.11.5 or later; that is the version the hooks were tested with.

- [Environment plugin development guide](https://mise.jdx.dev/env-plugin-development.html)
