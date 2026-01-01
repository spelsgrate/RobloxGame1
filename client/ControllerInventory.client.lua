local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Ensure the Default Backpack UI is ON
local success, err = pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end)
if not success then warn("Failed to enable Backpack UI: " .. tostring(err)) end

local function getTools()
    local tools = {}
    
    -- Get tools from Backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, t in pairs(backpack:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    
    -- Get tool currently equipped
    local char = player.Character
    if char then
        local equipped = char:FindFirstChildWhichIsA("Tool")
        if equipped then
            table.insert(tools, equipped)
        end
    end
    
    -- Sort for consistency (optional but good)
    table.sort(tools, function(a, b) return a.Name < b.Name end)
    
    return tools
end

local function equipCycle(direction)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local tools = getTools()
    if #tools == 0 then return end
    
    local currentTool = char:FindFirstChildWhichIsA("Tool")
    local currentIndex = 0
    
    -- Find index of current tool in our sorted list
    if currentTool then
        for i, t in ipairs(tools) do
            if t == currentTool then
                currentIndex = i
                break
            end
        end
    end
    
    -- Calculate New Index
    local newIndex = currentIndex + direction
    
    -- Wrap around
    if newIndex > #tools then 
        newIndex = 1 
    elseif newIndex < 1 then 
        newIndex = #tools 
    end
    
    -- Equip
    local newTool = tools[newIndex]
    if newTool and newTool ~= currentTool then
        hum:EquipTool(newTool)
    end
end

local function handleInput(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        if actionName == "EquipNext" then
            equipCycle(1)
        elseif actionName == "EquipPrev" then
            equipCycle(-1)
        end
    end
end

-- Bind L1 (Previous) and R1 (Next)
ContextActionService:BindAction("EquipPrev", handleInput, false, Enum.KeyCode.ButtonL1)
ContextActionService:BindAction("EquipNext", handleInput, false, Enum.KeyCode.ButtonR1)

print("Controller Inventory Loaded: L1/R1 to cycle tools.")
