--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Projectile = {}

function Projectile.CreateArrow(startPosition: Vector3, direction: Vector3, damage: number, source: Instance?)
    -- Create arrow part
    local arrow = Instance.new("Part")
    arrow.Name = "Arrow"
    arrow.Size = Vector3.new(0.3, 0.3, 2)
    arrow.Material = Enum.Material.Wood
    arrow.BrickColor = BrickColor.new("Brown")
    arrow.CFrame = CFrame.lookAt(startPosition, startPosition + direction) * CFrame.new(0, 0, -1)
    arrow.CanCollide = false
    arrow.Parent = workspace
    
    -- Add velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = direction * 80 -- Arrow speed
    bodyVelocity.Parent = arrow
    
    -- Cleanup after 5 seconds
    Debris:AddItem(arrow, 5)
    
    -- Hit detection
    local hitConnection
    hitConnection = arrow.Touched:Connect(function(hit)
        if hit:IsDescendantOf(source) then
            return -- Don't hit self
        end
        
        -- Find character
        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            -- Apply damage
            local CombatSystem = require(ReplicatedStorage.Shared.Combat.CombatSystem)
            CombatSystem:ApplyDamage(character, damage, source)
            
            -- Destroy arrow
            hitConnection:Disconnect()
            arrow:Destroy()
        elseif not hit.Parent:IsA("Model") then
            -- Hit terrain or non-character part
            hitConnection:Disconnect()
            bodyVelocity:Destroy()
            arrow.Anchored = true
            Debris:AddItem(arrow, 2)
        end
    end)
    
    return arrow
end

return Projectile
