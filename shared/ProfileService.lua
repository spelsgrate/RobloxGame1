--!strict
-- MOCK ProfileService to prevent DataManager from stalling
-- This is a temporary file until the real ProfileService is installed.

local ProfileService = {}

local MockProfile = {
    Data = {},
    Release = function() end,
    ListenToRelease = function() end,
    AddUserId = function() end,
    Identify = function() end,
    SetMetaTag = function() end,
}

local MockStore = {}

function MockStore:LoadProfileAsync(profileKey, notReleasedHandler)
    -- Simulate async load
    task.wait(0.1)
    return {
        Data = {
            Cash = 0,
            XP = 0,
            Level = 1
        },
        Release = function() end,
        ListenToRelease = function() end,
        AddUserId = function() end,
        Reconcile = function() end
    }
end

function ProfileService.GetProfileStore(p1, p2)
    return MockStore
end

return ProfileService
