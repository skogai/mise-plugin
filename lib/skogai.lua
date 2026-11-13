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

--- A value already in the environment when the hook runs, or nil when unset or empty.
--- It was set by the shell, by a config file that loads earlier, or by an `[env]` entry above the directive.
--- @param name string
--- @return string|nil
function M.existing(name)
    local value = os.getenv(name)
    if value ~= nil and value ~= "" then
        return value
    end
    return nil
end

--- First non-empty line of a file, or nil.
--- @param path string
--- @return string|nil
local function first_line(path)
    local f = io.open(path, "r")
    if f == nil then
        return nil
    end
    local line = f:read("*l")
    f:close()
    if line ~= nil then
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            return line
        end
    end
    return nil
end

--- Host name, read without running a command: the kernel's host name on Linux, then `/etc/hostname`,
--- then `$HOSTNAME`. Empty when none is available; config can set `SKOGAI_HOST` instead.
--- @return string
function M.host()
    return first_line("/proc/sys/kernel/hostname") or first_line("/etc/hostname") or M.existing("HOSTNAME") or ""
end

--- mise's names for platforms, as in `mise.lock` and the `os()` and `arch()` template functions.
local OS_NAMES = { darwin = "macos" }
local ARCH_NAMES = { amd64 = "x64", ["386"] = "x86" }

--- Operating system in mise's naming: `linux`, `macos`, `windows`.
--- @return string
function M.os()
    return OS_NAMES[RUNTIME.osType] or RUNTIME.osType
end

--- CPU architecture in mise's naming: `x64`, `arm64`.
--- @return string
function M.arch()
    return ARCH_NAMES[RUNTIME.archType] or RUNTIME.archType
end

return M
