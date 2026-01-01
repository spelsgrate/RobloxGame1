local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function getDragonSeat()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return nil end
    local seat = hum.SeatPart
    
    if seat and seat.Name == "DragonSeat" then
        return seat, seat.Parent -- Seat, Model
    end
    return nil
end

local verticalInput = 0

local function handleFlight(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        if actionName == "FlyUp" then
            verticalInput = 1
        elseif actionName == "FlyDown" then
            verticalInput = -1
        end
    elseif inputState == Enum.UserInputState.End then
        verticalInput = 0
    end
end

ContextActionService:BindAction("FlyUp", handleFlight, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA) -- A on Xbox
ContextActionService:BindAction("FlyDown", handleFlight, true, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB) -- B on Xbox

ContextActionService:SetTitle("FlyUp", "Ascend")
ContextActionService:SetTitle("FlyDown", "Descend")

-- Update Loop
RunService.Stepped:Connect(function()
    local seat, dragonModel = getDragonSeat()
    if seat and dragonModel then
        -- Sync Input to Server Model Attribute
        -- Check if value needs update to save bandwidth
        local current = dragonModel:GetAttribute("VerticalInput") or 0
        if current ~= verticalInput then
            dragonModel:SetAttribute("VerticalInput", verticalInput) -- Note: Client setting attribute replicates??
            -- WAIT: Client setting attribute on Server-owned object DOES NOT replicate to server.
            -- We need a RemoteEvent. Attribute is easiest for local prediction, but Server needs the value.
            -- Since we don't have a specific remote yet, let's use a RemoteEvent.
            
            -- ACTUALLY: VehicleSeat inputs replicate. Custom attributes DO NOT.
            -- I need to create a Remote for this.
            local remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
            local inputEvent = remotes and remotes:FindFirstChild("FlightInput")
            if not inputEvent then
                 -- If remote missing, fallback? (Or we fix MountHandler to create it)
            else
                 inputEvent:FireServer(dragonModel, verticalInput)
            end
        end
    end
end)
