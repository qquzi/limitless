-- very tuff skidding
local config = require("config")

local StringEncoder = require("modules/string_encoder")
local VariableRenamer = require("modules/variable_renamer")
local ControlFlowObfuscator = require("modules/control_flow_obfuscator")
local GarbageCodeInserter = require("modules/garbage_code_inserter")
local OpaquePredicateInjector = require("modules/opaque_predicate_injector")
local FunctionInliner = require("modules/function_inliner")
local DynamicCodeGenerator = require("modules/dynamic_code_generator")
local BytecodeEncoder = require("modules/bytecode_encoder")
local Watermarker = require("modules/watermark")
local Compressor = require("modules/compressor")
local StringToExpressions = require("modules/StringToExpressions")
local WrapInFunction = require("modules/WrapInFunction")
local VirtualMachinery = require("modules/VMGenerator")
local AntiTamper = require("modules/antitamper")

local Pipeline = {}

local function run_pass(name, fn, code)
    local ok, result = pcall(fn, code)

    if not ok then
        error(("pipeline pass '%s' failed:\n%s"):format(name, tostring(result)), 0)
    end

    if type(result) ~= "string" then
        error(("pipeline pass '%s' returned %s instead of string"):format(
            name,
            typeof and typeof(result) or type(result)
        ), 0)
    end

    return result
end

function Pipeline.process(code)
    if type(code) ~= "string" then
        error("pipeline expected source code string", 0)
    end

    local settings = config.get("settings")

    local passes = {
        {
            name = "string_encoder",
            enabled = settings.string_encoding.enabled,
            execute = function(src)
                return StringEncoder.process(src)
            end
        },

        {
            name = "garbage_code_pre",
            enabled = settings.garbage_code.enabled,
            execute = function(src)
                return GarbageCodeInserter.process(
                    src,
                    settings.garbage_code.garbage_blocks
                )
            end
        },

        {
            name = "dynamic_code",
            enabled = settings.dynamic_code.enabled,
            execute = function(src)
                return DynamicCodeGenerator.process(src)
            end
        },

        {
            name = "opaque_predicates",
            enabled = settings.opaque_predicates.enabled,
            execute = function(src)
                return OpaquePredicateInjector.process(src)
            end
        },

        {
            name = "bytecode_encoder",
            enabled = settings.bytecode_encoding.enabled,
            execute = function(src)
                return BytecodeEncoder.process(src)
            end
        },

        {
            name = "function_inlining",
            enabled = settings.function_inlining.enabled,
            execute = function(src)
                return FunctionInliner.process(src)
            end
        },

        {
            name = "string_to_expressions",
            enabled = settings.StringToExpressions.enabled,
            execute = function(src)
                return StringToExpressions.process(
                    src,
                    settings.StringToExpressions.min_number_length,
                    settings.StringToExpressions.max_number_length
                )
            end
        },

        {
            name = "antitamper",
            enabled = settings.antitamper.enabled,
            execute = function(src)
                return AntiTamper.process(src)
            end
        },

        {
            name = "virtual_machine",
            enabled = settings.VirtualMachine.enabled,
            execute = function(src)
                return VirtualMachinery.process(src)
            end
        },

        {
            name = "control_flow",
            enabled = settings.control_flow.enabled,
            execute = function(src)
                return ControlFlowObfuscator.process(
                    src,
                    settings.control_flow.max_fake_blocks
                )
            end
        },

        {
            name = "garbage_code_post",
            enabled = settings.garbage_code.enabled,
            execute = function(src)
                return GarbageCodeInserter.process(
                    src,
                    settings.garbage_code.garbage_blocks
                )
            end
        },

        {
            name = "variable_renaming",
            enabled = settings.variable_renaming.enabled,
            execute = function(src)
                return VariableRenamer.process(src, {
                    min_length = settings.variable_renaming.min_name_length,
                    max_length = settings.variable_renaming.max_name_length
                })
            end
        },

        {
            name = "compressor",
            enabled = settings.compressor.enabled,
            execute = function(src)
                return Compressor.process(src)
            end
        },

        {
            name = "wrap_in_function",
            enabled = settings.WrapInFunction.enabled,
            execute = function(src)
                return WrapInFunction.process(src)
            end
        },

        {
            name = "watermark",
            enabled = settings.watermark_enabled,
            execute = function(src)
                return Watermarker.process(src)
            end
        }
    }

    for i = 1, #passes do
        local pass = passes[i]

        if pass.enabled then
            code = run_pass(pass.name, pass.execute, code)
        end
    end

    return code
end

return Pipeline
