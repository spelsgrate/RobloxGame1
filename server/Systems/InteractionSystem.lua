--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionSystem = {}

-- Ensure Remote Exists
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local DropEvent = Remotes:FindFirstChild("DropItem") or Instance.new("RemoteEvent")
DropEvent.Name = "DropItem"
DropEvent.Parent = Remotes

function InteractionSystem:Init()
    print("InteractionSystem Initializing...")
    
    DropEvent.OnServerEvent:Connect(function(player)
        local char = player.Character
        if not char then return end
        
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool then
            -- DROP LOGIC
            tool.Parent = workspace
            
            -- Move it slightly forward so they don't pick it up instantly
            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("HumanoidRootPart") or tool.PrimaryPart
            if handle and handle:IsA("BasePart") then
                handle.CFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            end
            
            print(player.Name .. " dropped " .. tool.Name)
        end
    end)
end

return InteractionSystem
