--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local systemsFolder = script.Parent:WaitForChild("Systems", 10)

if not systemsFolder then
    error("Loader: Systems folder not found!")
    return
end

-- Prevent duplicate execution
if _G.ServerSystemsLoaded then
    return
end
_G.ServerSystemsLoaded = true

print("🚀 SERVER LOADER STARTED")

-- Load systems in order
local loadOrder = {
    "RemotesManager",
    "DataManager",
    "SimpleWorldGen",
    "TamingHandler",
    "MountHandler",
    "InteractionSystem",
    "NPCSpawner",
}

for _, systemName in ipairs(loadOrder) do
    local module = systemsFolder:FindFirstChild(systemName)
    if module and module:IsA("ModuleScript") then
        print("  ▶ Loading: " .. systemName)
        local success, result = pcall(function()
            local sys = require(module)
            if type(sys) == "table" and type(sys.Init) == "function" then
                sys:Init()
            end
        end)
        
        if not success then
            warn("  ❌ Failed to load " .. systemName .. ": " .. tostring(result))
        end
    end
end

print("✅ SERVER LOADER FINISHED")
