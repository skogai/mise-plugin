--- Shared option handling for the skogai env plugin hooks.
local file = require("file")

local M = {}

--- Plugin options as a table. A bare string directive value is ignored.
--- @param ctx MiseEnvCtx|MisePathCtx
--- @return table
function M.options(ctx)
    if type(ctx.options) == "table" then
        return ctx.options
    end
    return {}
end

--- Expand a leading `~` and resolve a relative path against `base`.
--- @param path string
--- @param base string
--- @return string
function M.resolve(path, base)
    local home = os.getenv("HOME") or ""
    if path == "~" then
        return home
    end
    if path:sub(1, 2) == "~/" then
        return file.join_path(home, path:sub(3))
    end
    if path:sub(1, 1) == "/" then
        return path
    end
    while path:sub(1, 2) == "./" do
        path = path:sub(3)
    end
    if path == "" or path == "." then
        return base
    end
    return file.join_path(base, path)
end

--- Workspace root: the `root` option, or the directory of the config that declares the plugin.
--- @param ctx MiseEnvCtx|MisePathCtx
--- @return string
function M.root(ctx)
    local root = M.options(ctx).root
    if type(root) == "string" and root ~= "" then
        return M.resolve(root, ctx.config_root)
    end
    return ctx.config_root
end

--- SkogAI config directory: the `config_dir` option, or `$XDG_CONFIG_HOME/skogai`.
--- @param ctx MiseEnvCtx|MisePathCtx
--- @return string
function M.config_dir(ctx)
    local dir = M.options(ctx).config_dir
    if type(dir) == "string" and dir ~= "" then
        return M.resolve(dir, M.root(ctx))
    end
    local xdg = os.getenv("XDG_CONFIG_HOME")
    if xdg == nil or xdg == "" then
        xdg = M.resolve("~/.config", "")
    end
    return file.join_path(xdg, "skogai")
end

--- Existing directories from the `paths` option, resolved against the root, without duplicates.
--- @param ctx MiseEnvCtx|MisePathCtx
--- @return string[]
function M.paths(ctx)
    local paths = M.options(ctx).paths
    local root = M.root(ctx)
    local seen = {}
    local result = {}
    if type(paths) ~= "table" then
        return result
    end
    for _, path in ipairs(paths) do
        if type(path) == "string" and path ~= "" then
            local dir = M.resolve(path, root)
            if not seen[dir] and file.exists(dir) then
                seen[dir] = true
                table.insert(result, dir)
            end
        end
    end
    return result
end

return M
