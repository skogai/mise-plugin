--- Returns environment variables to set when this plugin is active
--- Documentation: https://mise.jdx.dev/env-plugin-development.html#miseenv-hook
--- @param ctx MiseEnvCtx Options from the `_.skogai` directive and the declaring config's root
--- @return EnvKey[] List of environment variable definitions with key/value pairs
function PLUGIN:MiseEnv(ctx)
    local skogai = require("lib.skogai")

    --- A default that keeps a value already set before the hook runs.
    local function default(key, compute)
        return { key = key, value = skogai.existing(key) or compute() }
    end

    return {
        { key = "SKOGAI_MONOREPO_DIR", value = skogai.root(ctx) },
        { key = "SKOGAI_CONFIG_DIR", value = skogai.config_dir(ctx) },
        default("SKOGAI_HOST", skogai.host),
        default("SKOGAI_OS", skogai.os),
        default("SKOGAI_ARCH", skogai.arch),
    }
end
