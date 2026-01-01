local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DropEvent = Remotes:WaitForChild("DropItem")
local MountEvent = Remotes:WaitForChild("MountStateChanged")

local ACTION_DROP = "DropItemAction"
local isMounted = false

-- Listen for mount state
MountEvent.OnClientEvent:Connect(function(mounted)
    isMounted = mounted
end)

local function handleDrop(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        -- Don't drop if mounted (D-Pad Down is used for descend)
        if isMounted then return end
        
        -- Check if tool equipped
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChildWhichIsA("Tool") then
             DropEvent:FireServer()
        end
    end
end

-- Bind DPad Down (Console) and Q (PC alternative)
ContextActionService:BindAction(ACTION_DROP, handleDrop, true, Enum.KeyCode.DPadDown, Enum.KeyCode.Q)
ContextActionService:SetTitle(ACTION_DROP, "Drop Item")
print("InputController: Drop bound to DPadDown & Q")
ContextActionService:SetPosition(ACTION_DROP, UDim2.new(0.6, 0, 0.1, 0))
