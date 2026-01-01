--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatSystem = require(ReplicatedStorage.Shared.Combat.CombatSystem)
local Projectile = require(ReplicatedStorage.Shared.Combat.Projectile)

local HunterNPC = {}
HunterNPC.__index = HunterNPC

export type HunterNPC = {
    Model: Model,
    Humanoid: Humanoid,
    RootPart: BasePart,
    Target: Model?,
    LastAttackTime: number,
    GoldDrop: number,
}

function HunterNPC.new(spawnPosition: Vector3)
    local self = setmetatable({}, HunterNPC)
    
    -- Create model
    local model = Instance.new("Model")
    model.Name = "Hunter"
    
    -- Root
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Position = spawnPosition
    root.BrickColor = BrickColor.new("Bright red")
    root.Material = Enum.Material.Plastic
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.BrickColor = BrickColor.new("Bright yellow")
    head.Shape = Enum.PartType.Ball
    head.Parent = model
    
    local headWeld = Instance.new("WeldConstraint")
    headWeld.Part0 = root
    headWeld.Part1 = head
    headWeld.Parent = head
    head.CFrame = root.CFrame * CFrame.new(0, 1.5, 0)
    
    -- Torso
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.BrickColor = BrickColor.new("Brown")
    torso.Material = Enum.Material.Fabric
    torso.Parent = model
    
    local torsoWeld = Instance.new("WeldConstraint")
    torsoWeld.Part0 = root
    torsoWeld.Part1 = torso
    torsoWeld.Parent = torso
    torso.CFrame = root.CFrame
    
    -- Humanoid
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    humanoid.WalkSpeed = 12
    humanoid.Parent = model
    
    self.Model = model
    self.Humanoid = humanoid
    self.RootPart = root
    self.Target = nil
    self.LastAttackTime = 0
    self.GoldDrop = math.random(10, 25)
    
    -- Add health bar
    CombatSystem:CreateHealthBar(model)
    
    -- Add to workspace
    model.Parent = workspace
    
    -- Start AI loop
    task.spawn(function()
        self:AILoop()
    end)
    
    -- Handle death
    humanoid.Died:Connect(function()
        self:OnDeath()
    end)
    
    return self
end

function HunterNPC:AILoop()
    while self.Model and self.Model.Parent and self.Humanoid.Health > 0 do
        task.wait(0.5)
        
        -- Find nearest player
        local nearestPlayer, nearestDistance = self:FindNearestPlayer()
        
        if nearestPlayer and nearestDistance then
            self.Target = nearestPlayer.Character
            
            if nearestDistance < 50 then
                -- In attack range - stop and shoot
                self.Humanoid:MoveTo(self.RootPart.Position)
                self:TryAttack(nearestPlayer.Character)
            elseif nearestDistance < 150 then
                -- Chase player
                self:ChaseTarget(nearestPlayer.Character)
            else
                -- Too far, idle
                self.Target = nil
            end
        else
            -- No players, idle
            self.Target = nil
        end
    end
end

function HunterNPC:FindNearestPlayer()
    local nearest = nil
    local nearestDist = math.huge
    
    for _, player in Players:GetPlayers() do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local distance = (player.Character.HumanoidRootPart.Position - self.RootPart.Position).Magnitude
                if distance < nearestDist then
                    nearest = player
                    nearestDist = distance
                end
            end
        end
    end
    
    return nearest, nearestDist
end

function HunterNPC:ChaseTarget(target: Model)
    if not target or not target:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- Simple pathfinding
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(self.RootPart.Position, target.HumanoidRootPart.Position)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        if waypoints[2] then
            self.Humanoid:MoveTo(waypoints[2].Position)
        else
            self.Humanoid:MoveTo(target.HumanoidRootPart.Position)
        end
    else
        -- Direct chase
        self.Humanoid:MoveTo(target.HumanoidRootPart.Position)
    end
end

function HunterNPC:TryAttack(target: Model)
    local currentTime = os.clock()
    if currentTime - self.LastAttackTime < 2 then
        return -- Attack cooldown
    end
    
    if not target or not target:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    self.LastAttackTime = currentTime
    
    -- Calculate direction
    local direction = (target.HumanoidRootPart.Position - self.RootPart.Position).Unit
    
    -- Shoot arrow
    local startPos = self.RootPart.Position + Vector3.new(0, 1, 0)
    Projectile.CreateArrow(startPos, direction, 10, self.Model)
    
    print("Hunter attacked " .. target.Name)
end

function HunterNPC:OnDeath()
    print("Hunter defeated! Dropped " .. self.GoldDrop .. " gold")
    
    -- Drop gold (create a pickup part)
    local goldPart = Instance.new("Part")
    goldPart.Name = "GoldDrop"
    goldPart.Size = Vector3.new(1, 1, 1)
    goldPart.Shape = Enum.PartType.Ball
    goldPart.Material = Enum.Material.Neon
    goldPart.BrickColor = BrickColor.new("New Yeller")
    goldPart.Position = self.RootPart.Position + Vector3.new(0, 2, 0)
    goldPart.Anchored = false
    goldPart.CanCollide = true
    goldPart:SetAttribute("GoldAmount", self.GoldDrop)
    goldPart.Parent = workspace
    
    -- Auto-collect on touch
    goldPart.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            -- Award gold (DataManager handles this)
            local DataManager = require(game:GetService("ServerScriptService").Systems.DataManager)
            local profile = DataManager:GetProfile(player)
            if profile then
                profile.Data.Gold = (profile.Data.Gold or 0) + self.GoldDrop
                print("💰 " .. player.Name .. " collected " .. self.GoldDrop .. " gold")
            end
            goldPart:Destroy()
        end
    end)
    
    -- Cleanup after 30 seconds
    game:GetService("Debris"):AddItem(goldPart, 30)
    
    -- Destroy hunter model after 2 seconds
    task.wait(2)
    if self.Model and self.Model.Parent then
        self.Model:Destroy()
    end
end

return HunterNPC
