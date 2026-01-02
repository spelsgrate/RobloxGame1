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
local BASE_SPEED = 25
local BOOST_MULTIPLIER = 2.0
local TURN_SPEED = 2.0
local VERTICAL_SPEED = 80 -- Increased from 40 to overcome gravity
local DEADZONE = 0.15 -- Ignore small stick movements

-- Physics Objects
local bodyVel = nil
local alignOrient = nil

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
    lv.RelativeTo = Enum.ActuatorRelativeTo.World -- World space for proper movement
    lv.Parent = dragonRoot
    
    -- TIGHT CONTROLS: AlignOrientation for instant camera following
    local ao = Instance.new("AlignOrientation")
    ao.Name = "FlightAlign"
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.Attachment0 = attachment
    ao.RigidityEnabled = false
    ao.Responsiveness = 50 -- Very snappy
    ao.MaxTorque = math.huge
    ao.Parent = dragonRoot
    
    return lv, ao
end

mountEvent.OnClientEvent:Connect(function(mounted, dragonModel)
    if mounted then
        currentDragon = dragonModel
        isMounted = true
        
        -- Setup Physics
        local root = currentDragon:FindFirstChild("HumanoidRootPart")
        if root then
            local lv, ao = setupPhysics(root)
            bodyVel = lv
            alignOrient = ao
        end
    else
        isMounted = false
        currentDragon = nil
        if bodyVel then bodyVel:Destroy() end
        if alignOrient then alignOrient:Destroy() end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not isMounted or not currentDragon or not bodyVel or not alignOrient then return end
    
    local root = currentDragon.HumanoidRootPart
    
    -- INPUTS
    local throttleInput = 0  -- Forward/Backward (Y-axis)
    local strafeInput = 0    -- Left/Right (X-axis)
    local boost = false
    
    local camera = workspace.CurrentCamera
    
    -- Gamepad Input
    local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    if #state > 0 then
        for _, input in ipairs(state) do
            if input.KeyCode == Enum.KeyCode.ButtonR2 then
                throttleInput = input.Position.Z -- R2 for boost/throttle
            elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
                -- Left stick: Y-axis for forward/back, X-axis for strafe
                local stickY = processAxis(input.Position.Y, DEADZONE)
                local stickX = processAxis(input.Position.X, DEADZONE)
                
                throttleInput = math.max(throttleInput, stickY)
                strafeInput = stickX
            elseif input.KeyCode == Enum.KeyCode.ButtonB then -- Circle/B = Boost
                boost = true
            end
        end
    end
    
    -- Keyboard Fallback (WASD)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then throttleInput = 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then throttleInput = -1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then strafeInput = -1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then strafeInput = 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then boost = true end
    

    
    -- OMNI-DIRECTIONAL CAMERA-RELATIVE FLIGHT PHYSICS
    local currentSpeed = BASE_SPEED
    if boost then currentSpeed = currentSpeed * BOOST_MULTIPLIER end
    
    local velocity = Vector3.zero
    
    if camera and (throttleInput ~= 0 or strafeInput ~= 0) then
        -- Calculate forward and strafe components relative to camera
        local forwardComponent = camera.CFrame.LookVector * (throttleInput * currentSpeed * 2)
        local strafeComponent = camera.CFrame.RightVector * (strafeInput * currentSpeed * 2)
        
        -- Combine both vectors for omni-directional movement
        velocity = forwardComponent + strafeComponent
    end
    
    -- SAFETY: Prevent dragon from going too low (below Y = -500)
    if root.Position.Y < -500 and velocity.Y < 0 then
        velocity = Vector3.new(velocity.X, 0, velocity.Z)
        warn("Dragon too low! Preventing further descent.")
    end
    
    -- Apply velocity
    bodyVel.VectorVelocity = velocity
    

    
    -- TIGHT FLIGHT: Direct CFrame control with AlignOrientation
    if camera then
        local cameraCF = camera.CFrame
        
        if throttleInput ~= 0 or strafeInput ~= 0 then
            -- Calculate roll banking based on STRAFE input for physical dodge feel
            local rollAngle = 0
            
            if strafeInput ~= 0 then
                -- Roll into the strafe direction (left = negative, right = positive)
                rollAngle = strafeInput * math.rad(30) -- 30 degree max bank angle
            else
                -- If not strafing, bank based on camera turning
                local currentLook = root.CFrame.LookVector
                local targetLook = cameraCF.LookVector
                
                local currentFlat = Vector3.new(currentLook.X, 0, currentLook.Z)
                local targetFlat = Vector3.new(targetLook.X, 0, targetLook.Z)
                
                if currentFlat.Magnitude > 0.01 and targetFlat.Magnitude > 0.01 then
                    currentFlat = currentFlat.Unit
                    targetFlat = targetFlat.Unit
                    
                    local turnCross = currentFlat:Cross(targetFlat)
                    local turnAmount = math.asin(math.clamp(turnCross.Y, -1, 1))
                    rollAngle = -turnAmount * 0.8
                end
            end
            
            -- Set dragon orientation to camera + roll banking
            alignOrient.CFrame = cameraCF * CFrame.Angles(0, 0, rollAngle)
        else
            -- No throttle: level out (remove roll)
            local levelCF = CFrame.lookAt(root.Position, root.Position + camera.CFrame.LookVector)
            alignOrient.CFrame = levelCF
        end
    end
end)
