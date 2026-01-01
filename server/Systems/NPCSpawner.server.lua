--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HunterNPC = require(ReplicatedStorage.Shared.NPCs.HunterNPC)

local NPCSpawner = {}
local activeHunters = {}
local MAX_HUNTERS = 6

function NPCSpawner:Init()
    print("⚔️  NPCSpawner: Initializing...")
    
    -- Wait for world to generate
    task.wait(5)
    
    -- Start spawn loop
    task.spawn(function()
        self:SpawnLoop()
    end)
end

function NPCSpawner:SpawnLoop()
    while true do
        task.wait(10) -- Spawn check every 10 seconds
        
        -- Clean up dead hunters from tracking
        for i = #activeHunters, 1, -1 do
            if not activeHunters[i].Model or not activeHunters[i].Model.Parent then
                table.remove(activeHunters, i)
            end
        end
        
        -- Spawn new hunters if under limit
        if #activeHunters < MAX_HUNTERS then
            self:SpawnHunter()
        end
    end
end

function NPCSpawner:SpawnHunter()
    local spawnFolder = Workspace:FindFirstChild("HunterSpawns")
    if not spawnFolder then
        warn("NPCSpawner: No HunterSpawns folder found!")
        return
    end
    
    local spawns = spawnFolder:GetChildren()
    if #spawns == 0 then
        warn("NPCSpawner: No spawn points!")
        return
    end
    
    -- Pick random spawn
    local spawnMarker = spawns[math.random(1, #spawns)]
    local spawnPos = spawnMarker.Position
    
    -- Create hunter
    local hunter = HunterNPC.new(spawnPos)
    table.insert(activeHunters, hunter)
    
    print("  🏹 Spawned Hunter at " .. spawnMarker.Name .. " (Total: " .. #activeHunters .. ")")
end

return NPCSpawner
