local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local mountEvent = remotes:WaitForChild("MountStateChanged")

local currentDragon = nil
local isMounted = false

-- Flight Params
local BASE_SPEED = 50
local BOOST_MULTIPLIER = 2.0
local TURN_SPEED = 2.0
local VERTICAL_SPEED = 40
local DEADZONE = 0.15 -- Ignore small stick movements

-- Physics Objects
local bodyVel = nil
local bodyGyro = nil

-- Helper: Apply Deadzone and Exponential Curve
local function processAxis(value, deadzone)
    if math.abs(value) < deadzone then return 0 end
    -- Exponential curve for smooth control
    local sign = value > 0 and 1 or -1
    local normalized = (math.abs(value) - deadzone) / (1 - deadzone)
    return sign * (normalized ^ 1.5) -- Slight curve
end

local function setupPhysics(dragonRoot)
    -- PHYSICS SETUP
    local attachment = dragonRoot:FindFirstChild("RootAttachment") or Instance.new("Attachment", dragonRoot)
    attachment.Name = "RootAttachment"
    
    local lv = Instance.new("LinearVelocity")
    lv.Name = "FlightVelocity"
    lv.Attachment0 = attachment
    lv.MaxForce = math.huge
    lv.VectorVelocity = Vector3.zero
    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    lv.Parent = dragonRoot
    
    local av = Instance.new("AngularVelocity")
    av.Name = "FlightGyro"
    av.Attachment0 = attachment
    av.MaxTorque = math.huge
    av.AngularVelocity = Vector3.zero
    av.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    av.Parent = dragonRoot
    
    return lv, av
end

mountEvent.OnClientEvent:Connect(function(mounted, dragonModel)
    if mounted then
        currentDragon = dragonModel
        isMounted = true
        
        -- Setup Physics
        local root = currentDragon:FindFirstChild("HumanoidRootPart")
        if root then
            local lv, av = setupPhysics(root)
            bodyVel = lv
            bodyGyro = av
        end
        
        print("Dragon Controls: Engaged")
    else
        isMounted = false
        currentDragon = nil
        if bodyVel then bodyVel:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not isMounted or not currentDragon or not bodyVel or not bodyGyro then return end
    
    local root = currentDragon.HumanoidRootPart
    
    -- INPUTS
    local throttle = 0
    local brake = 0
    local steerX = 0
    local steerY = 0
    local vertical = 0
    local boost = false
    
    -- Gamepad Input
    local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    if #state > 0 then
        for _, input in ipairs(state) do
            if input.KeyCode == Enum.KeyCode.ButtonR2 then
                throttle = input.Position.Z -- 0 to 1
            elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
                brake = input.Position.Z
            elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
                -- Apply deadzone and curve
                steerX = processAxis(-input.Position.X, DEADZONE)
                steerY = processAxis(input.Position.Y, DEADZONE)
            elseif input.KeyCode == Enum.KeyCode.DPadUp then
                vertical = 1
            elseif input.KeyCode == Enum.KeyCode.DPadDown then
                vertical = -1
            elseif input.KeyCode == Enum.KeyCode.ButtonB then -- Circle/B = Boost
                boost = true
            end
        end
    end
    
    -- Keyboard Fallback
    if throttle == 0 and brake == 0 then
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then throttle = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then brake = 1 end
    end
    if steerX == 0 and steerY == 0 then
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then steerX = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then steerX = -1 end
    end
    if vertical == 0 then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -1 end
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then boost = true end
    
    -- PHYSICS CALC
    local currentSpeed = BASE_SPEED
    if boost then currentSpeed = currentSpeed * BOOST_MULTIPLIER end
    
    -- Forward/Backward
    local forwardSpeed = (throttle * currentSpeed * 2) - (brake * currentSpeed)
    
    -- Vertical
    local verticalSpeed = vertical * VERTICAL_SPEED
    
    -- Combined Velocity (Local Space: -Z is forward, Y is up)
    bodyVel.VectorVelocity = Vector3.new(0, verticalSpeed, -forwardSpeed)
    
    -- Rotation
    local pitch = steerY * TURN_SPEED
    local yaw = steerX * TURN_SPEED
    
    bodyGyro.AngularVelocity = Vector3.new(pitch, yaw, 0)
end)
