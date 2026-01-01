--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local function giveLoadout(player: Player)
    local backpack = player:WaitForChild("Backpack")
    
    -- Check if they already have it to avoid duplicates
    if backpack:FindFirstChild("Meat") then return end
    
    -- Create Meat Tool
    local tool = Instance.new("Tool")
    tool.Name = "Meat"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Color = Color3.fromRGB(200, 50, 50) -- Red meat color
    handle.Material = Enum.Material.Concrete
    handle.Parent = tool
    
    -- Tag it so TamingHandler finds it
    CollectionService:AddTag(tool, "DragonFood")
    
    tool.Parent = backpack
    
    -- Optional: Add to StarterGear for persistence
    local starterGear = player:FindFirstChild("StarterGear")
    if starterGear then
        tool:Clone().Parent = starterGear
    end
    print("ForceLoadout: Gave Meat to " .. player.Name)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        -- Wait a brief moment to ensure backpack exists
        task.wait(0.5)
        giveLoadout(player)
    end)
    
    -- Initial check for players already in game
    if player.Character then
        giveLoadout(player)
    end
end)
