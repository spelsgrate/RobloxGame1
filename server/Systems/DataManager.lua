--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Attempt to require ProfileService
local ProfileService
local success, result = pcall(function()
    return require(ReplicatedStorage:WaitForChild("ProfileService", 5))
end)

if not success then
    warn("CRITICAL: ProfileService module not found in ReplicatedStorage! Data Persistence will NOT work.")
    warn("Please install ProfileService into src/shared (ReplicatedStorage).")
else
    ProfileService = result
end

local DataManager = {}
DataManager.Profiles = {}

local ProfileTemplate = {
    Cash = 0,
    Level = 1,
    XP = 0,
    Gold = 0, -- NEW: Currency from defeating hunters
    RankTitle = "Hunter",
    Inventory = {},
    UnlockedMounts = {},
}

local ProfileStore = nil
if ProfileService then
    ProfileStore = ProfileService.GetProfileStore("PlayerProfile_v1", ProfileTemplate)
end

local function PlayerAdded(player: Player)
    if not ProfileStore then return end

    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing values from template
        
        -- Handle profile release (e.g. loaded on another server)
        profile:ListenToRelease(function()
            DataManager.Profiles[player] = nil
            player:Kick("Profile released (Joined another server?)")
        end)
        
        if player:IsDescendantOf(Players) then
            DataManager.Profiles[player] = profile
            print("Profile loaded for " .. player.Name)
        else
            -- Player left before profile loaded
            profile:Release()
        end
    else
        player:Kick("Could not load profile. Please rejoin.")
    end
end

local function PlayerRemoving(player: Player)
    local profile = DataManager.Profiles[player]
    if profile then
        profile:Release()
    end
end

function DataManager:Init()
    print("DataManager Initializing...")
    if not ProfileService then return end
    
    for _, player in Players:GetPlayers() do
        task.spawn(PlayerAdded, player)
    end
    
    Players.PlayerAdded:Connect(PlayerAdded)
    Players.PlayerRemoving:Connect(PlayerRemoving)
end

-- Helper to safely get data
function DataManager:Get(player: Player)
    local profile = self.Profiles[player]
    if profile then
        return profile.Data
    end
    return nil
end

-- Helper to get profile object
function DataManager:GetProfile(player: Player)
    return self.Profiles[player]
end

return DataManager
