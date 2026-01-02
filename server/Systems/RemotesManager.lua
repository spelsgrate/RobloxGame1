--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesManager = {}

function RemotesManager:Init()
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end
    
    local function ensureRemote(name, className)
        if not remotesFolder:FindFirstChild(name) then
            local remote = Instance.new(className)
            remote.Name = name
            remote.Parent = remotesFolder
        end
    end
    
    ensureRemote("DropItem", "RemoteEvent")
    ensureRemote("SolarFlare", "RemoteEvent")
    ensureRemote("MountStateChanged", "RemoteEvent")
    ensureRemote("QuestUpdate", "RemoteEvent")
    ensureRemote("Dismount", "RemoteEvent") -- NEW: For unmounting dragons
    
    print("RemotesManager: Verified Remotes.")
end

return RemotesManager
