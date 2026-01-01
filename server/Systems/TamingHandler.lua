--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local TamingHandler = {}

-- Store active Monster instances [Model] = MonsterObject
local ActiveMonsters = {} 

-- Helper to register monsters (In a real game, you'd call this when spawning)
-- For now, we'll scan workspace periodically or tag them
function TamingHandler:RegisterMonster(monsterObj)
    ActiveMonsters[monsterObj.Model] = monsterObj
end

function TamingHandler:Init()
    print("TamingHandler Initializing...")
    
    Workspace.ChildAdded:Connect(function(child)
        -- Check if it's food
        if CollectionService:HasTag(child, "DragonFood") or child.Name == "DragonFood" then
            TamingHandler:HandleFoodDropped(child)
        end
    end)
end

function TamingHandler:HandleFoodDropped(foodItem: Instance)
    print("DEBUG: Dropped item is a " .. foodItem.ClassName)

    local itemRoot = nil

    if foodItem:IsA("BasePart") then
        itemRoot = foodItem
    elseif foodItem:IsA("Tool") then
        -- Attempt to find Handle
        itemRoot = foodItem:WaitForChild("Handle", 2) or foodItem:FindFirstChildWhichIsA("BasePart")
    elseif foodItem:IsA("Model") then
        -- Attempt PrimaryPart or children
        itemRoot = foodItem.PrimaryPart or foodItem:FindFirstChild("Handle") or foodItem:FindFirstChild("Main") or foodItem:FindFirstChildWhichIsA("BasePart")
    end

    if not itemRoot then 
        warn("TamingHandler: Dropped item '" .. foodItem.Name .. "' (".. foodItem.ClassName ..") has no valid physical part!")
        return 
    end

    print("SUCCESS: Food detected at " .. tostring(itemRoot.Position))
    
    -- Find neareast beast
    local nearestBeast = nil
    local minDist = 30 -- Max sense range
    
    for model, monster in pairs(ActiveMonsters) do
        if monster.RootPart then
            local dist = (monster.RootPart.Position - itemRoot.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestBeast = monster
            end
        end
    end
    
    if nearestBeast then
        -- Command Beast
        print(nearestBeast.Model.Name .. " smells food!")
        nearestBeast:Follow(itemRoot)
        
        -- Eat logic (simple delay simulation)
        task.delay(2, function()
            if itemRoot and itemRoot.Parent then -- still exists
                local dist = (nearestBeast.RootPart.Position - itemRoot.Position).Magnitude
                if dist < 10 then
                    nearestBeast:Eat(itemRoot)
                    -- Queue Quest Progress
                    if itemRoot and itemRoot:FindFirstChild("DragonFood") or game:GetService("CollectionService"):HasTag(itemRoot.Parent, "DragonFood") or game:GetService("CollectionService"):HasTag(itemRoot, "DragonFood") then
                         -- Best guess at owner (for now, assume 'Adragonblocks' or find nearest)
                         -- PROTOTYPE: Just give progress to all players for testing
                         if _G.QuestManager then
                             for _, p in game:GetService("Players"):GetPlayers() do
                                 if p:GetAttribute("CurrentQuest") == "Taming101" then
                                     _G.QuestManager:AddProgress(p, 1)
                                 end
                             end
                         end
                    end
                end
            end
        end)
    end
end

return TamingHandler
