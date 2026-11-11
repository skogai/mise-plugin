--- Returns PATH entries to prepend when this plugin is active
--- Documentation: https://mise.jdx.dev/env-plugin-development.html#misepath-hook
--- @param ctx MisePathCtx Options from the `_.skogai` directive and the declaring config's root
--- @return string[] List of paths to prepend to PATH
function PLUGIN:MisePath(ctx)
    local skogai = require("lib.skogai")

    return skogai.paths(ctx)
end
