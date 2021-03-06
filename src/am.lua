local _cli = require"ami.internals.cli"
local _exec = require"ami.internals.exec"
local _interface = require"ami.internals.interface"
local _initialize_options = require"ami.internals.options.init"

require"ami.globals"

am = require"version-info"
require"ami.cache"
require"ami.app"
require"ami.plugin"
am.options = _initialize_options({
    APP_CONFIGURATION_CANDIDATES = {"app.hjson", "app.json"},
    BASE_INTERFACE = "app"
})

local function _get_interface(cmd, args)
    local _interface = cmd
    if util.is_array(cmd) then
        args = cmd
        _interface = am.__interface
    end
    if type(cmd) == "string" then
        local _commands = table.get(am, { "__interface", "commands" }, {})
        _interface = _commands[cmd] or _interface
    end
    return _interface, args
end

---#DES am.execute
---
---Executes cmd with specified args
---@param cmd string|string[]|AmiCli
---@param args string[]
---@return any
function am.execute(cmd, args)
    local _interface, args = _get_interface(cmd, args)
    ami_assert(type(_interface) == "table", "No valid command provided!", EXIT_CLI_CMD_UNKNOWN)
    return _cli.process(_interface, args)
end

---@type string[]
am.__args = {}

---#DES am.get_proc_args()
---
---Returns arguments passed to this process
---@return string[]
function am.get_proc_args()
    return util.clone(am.__args)
end

---#DES am.parse_args()
---
---Parses provided args in respect to command
---@param cmd string|string[]
---@param args string[]|AmiParseArgsOptions
---@param options AmiParseArgsOptions|nil
---@return table<string, string|number|boolean>, AmiCli|nil, CliArg[]:
function am.parse_args(cmd, args, options)
    local _interface, args = _get_interface(cmd, args)
    return _cli.parse_args(args, _interface, options)
end

---Parses provided args in respect to ami base
---@param args string[]
---@param options AmiParseArgsOptions
---@return table<string, string|number|boolean>, nil, CliArg[]
function am.__parse_base_args(args, options)
    if type(options) ~= "table" then
        options = { stopOnCommand = true }
    end
    return am.parse_args(_interface.new("base"), args, options)
end

---@class AmiPrintHelpOptions

---#DES am.print_help()
---
---Parses provided args in respect to ami base
---@param cmd string|string[]
---@param options AmiPrintHelpOptions
function am.print_help(cmd, options)
    if not cmd then
        cmd = am.__interface
    end
    if type(cmd) == "string" then
        cmd = am.__interface[cmd]
    end
    _cli.print_help(cmd, options)
end

---Reloads application interface and returns true if it is application specific. (False if it is from templates)
---@param shallow boolean
---@return boolean
function am.__reload_interface(shallow)
    local _isAppSpecific, _amiInterface = _interface.load(am.options.BASE_INTERFACE, shallow)
    am.__interface = _amiInterface
    return _isAppSpecific
end

if TEST_MODE then
    ---Overwrites ami interface (TEST_MODE only)
    ---@param ami AmiCli
    function am.__set_interface(ami)
        am.__interface = ami
    end

    ---Resets am options
    function am.__reset_options()
        am.options = _initialize_options({
            APP_CONFIGURATION_CANDIDATES = {"app.hjson", "app.json"},
            BASE_INTERFACE = "app"
        })
    end
end

---#DES am.execute_extension()
---
---Executes native lua extensions
---@param action string|function
---@param args CliArg[]|string[]
---@param options ExecNativeActionOptions
---@return any
am.execute_extension = _exec.native_action

---#DES am.execute_external()
---
---Executes external command
---@param command string
---@param args CliArg[]
---@param injectArgs string[]
---@return integer
am.execute_external = _exec.external_action