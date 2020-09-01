#!/usr/sbin/eli
local os = require "os"

-- extensions
require "ami.exit_codes"
require "ami.cli"
require "ami.util"
require "ami.init"
require "ami.app"
require "ami.plugin"
require "ami.tpl"
require "ami.sub"
-- extensions

require "eli.extensions.string":globalize()

local _info, _error = require "eli.util".global_log_factory("ami", "info", "error")

_preprocess_args = eliCli.parse_args

load_app_details()

local HELP_OPTION = {
    index = 100,
    aliases = {"h"},
    description = "Prints this help message"
}

local _cmdImplementationStatus = "(not installed)"
local _cmdImplementationError = EXIT_NOT_INSTALLED

if eliFs.exists("ami.lua") or eliFs.exists("ami.hjson") or eliFs.exists("ami.json") then
    _cmdImplementationStatus = "(not implemented)"
    _cmdImplementationError = EXIT_NOT_IMPLEMENTED
end

AMI = {
    id = "ami",
    title = "AMI",
    partial = false,
    commandRequired = false,
    includeOptionsInUsage = true,
    commandsIndexed = true,
    optionsIndexed = true,
    options = basicCliOptions,
    commands = {
        info = {
            index = 0,
            description = _cmdImplementationStatus .. " ami 'info' sub command",
            summary = _cmdImplementationStatus .. " Prints runtime info and status of the app",
            options = {
                help = HELP_OPTION
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                ami_error("Violation of AMI standard! " .. _cmdImplementationStatus, EXIT_NOT_IMPLEMENTED)
            end
        },
        setup = {
            index = 1,
            description = "ami 'setup' sub command",
            summary = "Run setups based on specified options app/configure",
            options = {
                help = HELP_OPTION,
                environment = {
                    index = 0,
                    description = "Creates application environment"
                },
                app = {
                    index = 1,
                    description = "Generates app folder structure and files"
                },
                configure = {
                    index = 2,
                    description = "Configures application and renders templates"
                },
                ["no-validate"] = {
                    index = 3,
                    description = "Disables platform and configuration validation"
                }
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                local _noOptions = #eliUtil.keys(_options) == 0

                local _subAmiLoaded = false
                if _noOptions or _options.environment then
                    prepare_app(APP)
                    -- no need to load sub ami in your app ami
                    _subAmiLoaded = load_sub_ami()
                end

                -- You should not use next 5 lines in your app
                if _noOptions or _options.app then
                    if _subAmiLoaded then
                        process_cli(AMI, arg)
                    end
                end

                if _noOptions or _options.configure then
                    render_templates(APP)
                end
            end
        },
        validate = {
            index = 2,
            description = _cmdImplementationStatus .. " ami 'validate' sub command",
            summary = _cmdImplementationStatus .. " Validates app configuration and platform support",
            options = {
                help = HELP_OPTION,
                platform = {
                    index = 1,
                    description = "Validates application platform"
                },
                configuration = {
                    index = 2,
                    description = "Validates application configuration"
                }
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                ami_error("Violation of AMI standard! " .. _cmdImplementationStatus, EXIT_NOT_IMPLEMENTED)
            end
        },
        start = {
            index = 3,
            aliases = {"s"},
            description = _cmdImplementationStatus .. " ami 'start' sub command ",
            summary = _cmdImplementationStatus .. " Starts the app",
            options = {
                help = HELP_OPTION
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                ami_error("Violation of AMI standard! " .. _cmdImplementationStatus, EXIT_NOT_IMPLEMENTED)
            end
        },
        stop = {
            index = 4,
            description = _cmdImplementationStatus .. " ami 'stop' sub command",
            summary = _cmdImplementationStatus .. " Stops the app",
            options = {
                help = HELP_OPTION
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                ami_error("Violation of AMI standard! " .. _cmdImplementationStatus, EXIT_NOT_IMPLEMENTED)
            end
        },
        update = {
            index = 5,
            description = "ami 'update' command",
            summary = "Updates the app or returns setup required",
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end

                local _available, _id, _ver = is_update_available()
                if _available then
                    ami_error(
                        "Found new version " .. _ver .. " of " .. _id .. ", please run setup...",
                        EXIT_SETUP_REQUIRED
                    )
                end
                log_info("Application is up to date.")
            end
        },
        remove = {
            index = 6,
            description = "ami 'remove' sub command",
            summary = "Remove the app or parts based on options",
            options = {
                help = HELP_OPTION,
                all = {
                    index = 2,
                    description = "Removes application data (usually equals app reset)"
                }
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end

                if _options.all then
                    remove_app()
                    log_success("Application removed.")
                else
                    remove_app_data()
                    log_success("Application data removed.")
                end
                return
            end
        },
        about = {
            index = 7,
            description = _cmdImplementationStatus .. " ami 'about' sub command",
            summary = _cmdImplementationStatus .. " Prints informations about app",
            options = {
                help = HELP_OPTION
            },
            action = function(_options, command, args, cli)
                if _options.help then
                    show_cli_help(cli)
                    return
                end
                ami_error("Violation of AMI standard! " .. _cmdImplementationStatus, EXIT_NOT_IMPLEMENTED)
            end
        }
    },
    action = function(_options, command, args, cli)
        if _options.help then
            show_cli_help(cli)
            return
        end

        if _options.version then
            print(AMI_VERSION)
            return
        end

        if _options.about then
            print(AMI_ABOUT)
            return
        end

        if command then
            process_cli(command, args, {strict = {unknown = true}})
        else
            _error "No valid command provided!"
            os.exit(2)
        end
    end
}

load_sub_ami()
process_cli(AMI, arg)
