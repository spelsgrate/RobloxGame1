--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemotesManager = require(script.Parent:WaitForChild("RemotesManager")) -- Ensure remotes exist? Or just use raw check.

local MountHandler = {}

-- Ensure Remote
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FlightInputEvent = Remotes:FindFirstChild("FlightInput") or Instance.new("RemoteEvent")
FlightInputEvent.Name = "FlightInput"
FlightInputEvent.Parent = Remotes

function MountHandler:Init()
    print("MountHandler Initializing...")
    
    -- Input Listener (legacy)
    FlightInputEvent.OnServerEvent:Connect(function(player, dragonModel, verticalVal)
        -- Legacy input support (optional)
    end)
    
    -- Dismount Listener (NEW)
    task.spawn(function()
        local dismountEvent = Remotes:WaitForChild("Dismount", 10)
        if not dismountEvent then
            warn("MountHandler: Dismount remote not found!")
            return
        end
        
        print("MountHandler: Dismount listener connected")
        dismountEvent.OnServerEvent:Connect(function(player)
            print(player.Name .. " requested dismount")
            
            -- Find what dragon the player is mounted on
            for _, dragonModel in workspace:GetChildren() do
                if dragonModel:IsA("Model") and dragonModel:FindFirstChild("HumanoidRootPart") then
                    local weld = dragonModel.HumanoidRootPart:FindFirstChild("RiderWeld_"..player.Name)
                    if weld then
                        print("Found weld, unmounting from " .. dragonModel.Name)
                        MountHandler:UnmountDragon(player, dragonModel)
                        break
                    end
                end
            end
        end)
    end)
    
    local MountStateEvent = Remotes:FindFirstChild("MountStateChanged") or Instance.new("RemoteEvent")
    MountStateEvent.Name = "MountStateChanged"
    MountStateEvent.Parent = Remotes
    
    local function setupDragon(dragonModel)
        local root = dragonModel:WaitForChild("HumanoidRootPart", 5)
        if not root then return end
        
        -- Create Prompt
        if not root:FindFirstChild("MountPrompt") then
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "MountPrompt"
            prompt.ActionText = "Mount"
            prompt.ObjectText = "Dragon"
            prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
            prompt.HoldDuration = 0.5
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            prompt.RequiresLineOfSight = false
            prompt.Parent = root
            
            prompt.Triggered:Connect(function(player)
                MountHandler:MountDragon(player, dragonModel)
            end)
        end
    end

    -- Listen for new dragons
    game.Workspace.ChildAdded:Connect(function(child)
        if child:GetAttribute("IsDragon") or child.Name:find("Dragon") then
             setupDragon(child)
        end
    end)
    -- Check existing
    for _, child in ipairs(game.Workspace:GetChildren()) do
         if child.Name:find("Dragon") then setupDragon(child) end
    end
end

function MountHandler:MountDragon(player, dragonModel)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local dragonRoot = dragonModel:FindFirstChild("HumanoidRootPart")
    
    if hum and root and dragonRoot then
        -- Check if already mounted
        local existingWeld = dragonRoot:FindFirstChild("RiderWeld_"..player.Name)
        if existingWeld then
            -- Unmount
            self:UnmountDragon(player, dragonModel)
            return
        end
        
        -- 1. Weld Player
        hum.PlatformStand = true
        root.CFrame = dragonRoot.CFrame * CFrame.new(0, 4, 0)
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = dragonRoot
        weld.Part1 = root
        weld.Parent = dragonRoot
        weld.Name = "RiderWeld_"..player.Name
        
        -- 2. Disable Server Physics BEFORE setting network ownership
        local alignPos = dragonRoot:FindFirstChild("AlignPosition")
        local alignRot = dragonRoot:FindFirstChild("AlignOrientation")
        local antiGrav = dragonRoot:FindFirstChild("VectorForce")
        
        if alignPos then alignPos.Enabled = false end
        if alignRot then alignRot.Enabled = false end
        if antiGrav then antiGrav.Enabled = false end
        
        -- 3. Network Ownership (with error handling)
        local success, err = pcall(function()
            dragonRoot:SetNetworkOwner(player)
        end)
        
        if not success then
            warn("Failed to set network owner: " .. tostring(err))
        end
        
        -- 4. Notify Client
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        remotes.MountStateChanged:FireClient(player, true, dragonModel)
        
        -- Hide Prompt
        local prompt = dragonRoot:FindFirstChild("MountPrompt")
        if prompt then prompt.Enabled = false end
        
        print(player.Name .. " mounted " .. dragonModel.Name)
    end
end

function MountHandler:UnmountDragon(player, dragonModel)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local dragonRoot = dragonModel:FindFirstChild("HumanoidRootPart")
    
    if hum and dragonRoot then
        -- Remove weld
        local weld = dragonRoot:FindFirstChild("RiderWeld_"..player.Name)
        if weld then weld:Destroy() end
        
        -- Restore player
        hum.PlatformStand = false
        
        -- Re-enable server physics
        local alignPos = dragonRoot:FindFirstChild("AlignPosition")
        local alignRot = dragonRoot:FindFirstChild("AlignOrientation")
        
        if alignPos then alignPos.Enabled = true end
        if alignRot then alignRot.Enabled = true end
        
        -- Reset network ownership to server
        pcall(function()
            dragonRoot:SetNetworkOwner(nil)
        end)
        
        -- Notify Client
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        remotes.MountStateChanged:FireClient(player, false, dragonModel)
        
        -- Show Prompt
        local prompt = dragonRoot:FindFirstChild("MountPrompt")
        if prompt then prompt.Enabled = true end
        
        print(player.Name .. " unmounted " .. dragonModel.Name)
    end
end

return MountHandler
