--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleWorldGen = {}

function SimpleWorldGen:Init()
    print("🌍 SimpleWorldGen: Building world...")
    
    -- Run async to not block loader
    task.spawn(function()
        self:Generate()
    end)
end

function SimpleWorldGen:Generate()
    local Terrain = Workspace.Terrain
    
    -- 1. CREATE SPAWN PLATFORM FIRST
    local spawnHeight = 3 -- Match terrain surface
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Position = Vector3.new(0, spawnHeight + 1, 0) -- +1 to be on top of surface
    spawn.Size = Vector3.new(30, 2, 30)
    spawn.Anchored = true
    spawn.BrickColor = BrickColor.new("Bright green")
    spawn.Material = Enum.Material.Grass
    spawn.TopSurface = Enum.SurfaceType.Smooth
    spawn.CanCollide = true
    spawn.Parent = Workspace
    
    print("✅ Spawn Platform Created at Y=" .. spawnHeight)
    
    -- 2. Clear existing terrain
    Terrain:Clear()
    print("⚡ Clearing terrain...")
    
    -- 3. Create SOLID flat grass terrain (512x512 - NO HOLES)
    local mapSize = 512
    local centerY = -5 -- Underground level
    local blockSize = 8 -- Smaller blocks for better coverage
    
    -- Fill in overlapping pattern to ensure no gaps
    for x = -mapSize, mapSize, blockSize do
        for z = -mapSize, mapSize, blockSize do
            -- Fill terrain with grass (use larger blocks with overlap)
            Terrain:FillBlock(
                CFrame.new(x, centerY, z),
                Vector3.new(blockSize + 2, 16, blockSize + 2), -- +2 for overlap
                Enum.Material.Grass
            )
        end
        if x % 64 == 0 then task.wait() end -- Yield periodically
    end
    
    print("🌱 Grass terrain generated (512x512)")
    
    -- 4. Create Hunter Outpost in center
    self:CreateOutpost(Vector3.new(0, surfaceY, 80))
    
    print("🏰 Hunter Outpost created")
    
    -- 5. Mark Hunter spawn points (invisible markers at terrain surface)
    local hunterSpawns = Instance.new("Folder")
    hunterSpawns.Name = "HunterSpawns"
    hunterSpawns.Parent = Workspace
    
    local surfaceY = 3
    local spawnPositions = {
        Vector3.new(40, surfaceY, 0),
        Vector3.new(-40, surfaceY, 0),
        Vector3.new(0, surfaceY, 40),
        Vector3.new(0, surfaceY, -40),
        Vector3.new(30, surfaceY, 30),
        Vector3.new(-30, surfaceY, -30),
        Vector3.new(50, surfaceY, 50),
        Vector3.new(-50, surfaceY, -50),
    }
    
    for i, pos in ipairs(spawnPositions) do
        local marker = Instance.new("Part")
        marker.Name = "Spawn" .. i
        marker.Position = pos
        marker.Size = Vector3.new(2, 2, 2)
        marker.Anchored = true
        marker.Transparency = 1
        marker.CanCollide = false
        marker.Parent = hunterSpawns
    end
    
    print("📍 Hunter spawn points marked")
    
    print("✅ World Generation Complete!")
end

function SimpleWorldGen:CreateOutpost(position: Vector3)
    local outpost = Instance.new("Model")
    outpost.Name = "HunterOutpost"
    
    -- Base (start at Y=0)
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(30, 1, 30)
    base.Position = Vector3.new(position.X, 0.5, position.Z) -- Half-height = 0.5
    base.Anchored = true
    base.Material = Enum.Material.Cobblestone
    base.BrickColor = BrickColor.new("Dark stone grey")
    base.Parent = outpost
    
    -- Walls (built on top of base)
    local wallPositions = {
        {pos = Vector3.new(0, 8, 15), size = Vector3.new(30, 15, 2)},  -- Front
        {pos = Vector3.new(0, 8, -15), size = Vector3.new(30, 15, 2)}, -- Back
        {pos = Vector3.new(15, 8, 0), size = Vector3.new(2, 15, 30)},  -- Right
        {pos = Vector3.new(-15, 8, 0), size = Vector3.new(2, 15, 30)}, -- Left
    }
    
    for _, wallData in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Wall"
        wall.Size = wallData.size
        wall.Position = Vector3.new(position.X + wallData.pos.X, wallData.pos.Y, position.Z + wallData.pos.Z)
        wall.Anchored = true
        wall.Material = Enum.Material.Brick
        wall.BrickColor = BrickColor.new("Brown")
        wall.Parent = outpost
    end
    
    -- Tower
    local tower = Instance.new("Part")
    tower.Name = "Tower"
    tower.Size = Vector3.new(8, 20, 8)
    tower.Position = Vector3.new(position.X, 10, position.Z) -- Center at Y=10
    tower.Anchored = true
    tower.Material = Enum.Material.Concrete
    tower.BrickColor = BrickColor.new("Dark stone grey")
    tower.Parent = outpost
    
    -- Core (destructible part with HP)
    local core = Instance.new("Part")
    core.Name = "Core"
    core.Size = Vector3.new(4, 4, 4)
    core.Position = Vector3.new(position.X, 18, position.Z) -- Top of tower
    core.Anchored = true
    core.Material = Enum.Material.Neon
    core.BrickColor = BrickColor.new("Really red")
    core.Shape = Enum.PartType.Ball
    core.Parent = outpost
    
    -- Add HP attribute
    outpost:SetAttribute("Health", 1000)
    outpost:SetAttribute("MaxHealth", 1000)
    
    outpost.Parent = Workspace
end

return SimpleWorldGen
