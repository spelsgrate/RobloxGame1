--!strict
-- Prevent Duplicate Execution
if _G.AbilityControllerLoaded then return end
_G.AbilityControllerLoaded = true

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HapticService = game:GetService("HapticService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Ability State
local abilityCooldowns = {
    Primary = 0,
    Secondary = 0
}

local COOLDOWN_PRIMARY = 10 -- seconds
local COOLDOWN_SECONDARY = 5

-- Haptic Feedback Helper
local function vibrate(motor, intensity, duration)
    if HapticService then
        pcall(function()
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, intensity)
            task.delay(duration, function()
                HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, 0)
            end)
        end)
    end
end

-- Primary Ability (Triangle/ButtonY)
local function usePrimaryAbility()
    if os.clock() < abilityCooldowns.Primary then
        print("Primary on cooldown...")
        return
    end
    
    abilityCooldowns.Primary = os.clock() + COOLDOWN_PRIMARY
    print("PRIMARY ABILITY ACTIVATED")
    
    -- Haptic: Strong pulse
    vibrate(Enum.VibrationMotor.Large, 1, 0.3)
    
    -- Fire to server if needed (e.g., trigger Ultimate)
    -- local abilityRemote = Remotes:FindFirstChild("UseAbility")
    -- if abilityRemote then abilityRemote:FireServer("Primary") end
end

-- Secondary Ability (handled in DragonControls as Boost currently)
-- Could be expanded for special moves

-- Dismount (Square/ButtonX)
local function dismount()
    print("Dismounting...")
    vibrate(Enum.VibrationMotor.Small, 0.5, 0.2)
    
    local char = player.Character
    if char then
        local seat = char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
        if seat then
            char.Humanoid.Sit = false
            print("Dismounted!")
        end
    end
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Gamepad1 then
        if input.KeyCode == Enum.KeyCode.ButtonY then -- Triangle
            usePrimaryAbility()
        elseif input.KeyCode == Enum.KeyCode.ButtonX then -- Square
            dismount()
        end
    end
    
    -- Keyboard fallbacks
    if input.KeyCode == Enum.KeyCode.R then
        usePrimaryAbility()
    elseif input.KeyCode == Enum.KeyCode.F then
        dismount()
    end
end)

-- Haptic Feedback on Mount (listen for event)
local mountEvent = Remotes:WaitForChild("MountStateChanged")
mountEvent.OnClientEvent:Connect(function(mounted)
    if mounted then
        vibrate(Enum.VibrationMotor.Large, 0.8, 0.4)
        print("🎮 Haptic: Mounted")
    else
        vibrate(Enum.VibrationMotor.Small, 0.5, 0.2)
        print("🎮 Haptic: Dismounted")
    end
end)

print("AbilityController: Triangle=Ability, Circle=Boost, Square=Dismount")
