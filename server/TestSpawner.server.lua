--!strict
local CollectionService = game:GetService("CollectionService")
local StarterPack = game:GetService("StarterPack")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for systems to load
task.wait(3)

local MonsterClass = require(game:GetService("ReplicatedStorage").Beasts.Monster)
local FlyingMonster = require(game:GetService("ReplicatedStorage").Beasts.FlyingMonster)
local TamingHandler = require(ServerScriptService.Systems.TamingHandler)

local function createTestDragon()
    local model = Instance.new("Model")
    model.Name = "TestDragon"
    
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(6, 6, 6)
    root.Position = Vector3.new(15, 6, 0) -- Y=6 to be on terrain surface (3+3 for radius)
    root.CanCollide = true
    root.Transparency = 0
    root.Material = Enum.Material.Neon
    root.Color = Color3.fromRGB(255, 100, 50) -- Orange-Red
    root.Shape = Enum.PartType.Ball
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root
    
    -- Dragon Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(4, 4, 4)
    head.Color = Color3.fromRGB(255, 200, 50)
    head.Material = Enum.Material.Neon
    head.Shape = Enum.PartType.Ball
    head.Parent = model
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = head
    weld.Parent = root
    
    head.CFrame = root.CFrame * CFrame.new(0, 0, -5)
    
    -- Wings
    local function makeWing(side)
        local wing = Instance.new("Part")
        wing.Name = "Wing_" .. side
        wing.Size = Vector3.new(1, 8, 6)
        wing.Color = Color3.fromRGB(200, 50, 50)
        wing.Material = Enum.Material.Neon
        wing.Transparency = 0.3
        wing.Parent = model
        
        local wingWeld = Instance.new("WeldConstraint")
        wingWeld.Part0 = root
        wingWeld.Part1 = wing
        wingWeld.Parent = wing
        
        local offset = side == "Left" and -4 or 4
        wing.CFrame = root.CFrame * CFrame.new(offset, 0, 0) * CFrame.Angles(0, 0, math.rad(side == "Left" and 30 or -30))
    end
    
    makeWing("Left")
    makeWing("Right")
    
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 200
    humanoid.Health = 200
    humanoid.Parent = model
    
    model.Parent = workspace
    
    return model
end

local function createFoodTool()
    local tool = Instance.new("Tool")
    tool.Name = "Meat"
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Color = Color3.fromRGB(139, 69, 19) -- Brown
    handle.Material = Enum.Material.Concrete
    handle.Parent = tool
    
    -- Add Tag
    CollectionService:AddTag(handle, "DragonFood")
    
    tool.Parent = StarterPack
end

print("🐉 SPAWNING TEST DRAGON...")

-- Create Food
if not StarterPack:FindFirstChild("Meat") then
    createFoodTool()
    print("  ✅ Created 'Meat' tool")
end

-- Create Dragon (Use FlyingMonster for flight capability)
local dragonModel = createTestDragon()
local monster = FlyingMonster.new(dragonModel)

-- Give it to first player for testing
task.wait(2)
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
if player then
    monster:SetOwner(player)
    print("  ✅ TestDragon assigned to " .. player.Name)
end

-- Register with TamingHandler
TamingHandler:RegisterMonster(monster)
print("✅ TestDragon spawned and registered")

-- Simple wander behavior
task.spawn(function()
    while monster and monster.Model and monster.Model.Parent do
        task.wait(5)
        if not monster.Target and (not monster.Seat or not monster.Seat.Occupant) then
            local rX = math.random(-20, 20)
            local rZ = math.random(-20, 20)
            local targetPos = monster.RootPart.Position + Vector3.new(rX, 0, rZ)
            monster.Humanoid:MoveTo(targetPos)
        end
    end
end)
