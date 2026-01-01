--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Monster = require(script.Parent:WaitForChild("Monster"))

local FlyingMonster = {}
setmetatable(FlyingMonster, {__index = Monster})
FlyingMonster.__index = FlyingMonster

function FlyingMonster.new(model: Model)
    local self = Monster.new(model)
    setmetatable(self, FlyingMonster)
    
    -- Flight Setup
    self.FlightAttachment = Instance.new("Attachment")
    self.FlightAttachment.Name = "FlightAttachment"
    self.FlightAttachment.Parent = self.RootPart
    
    self.AlignPos = Instance.new("AlignPosition")
    self.AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    self.AlignPos.Attachment0 = self.FlightAttachment
    self.AlignPos.MaxForce = 100000
    self.AlignPos.Responsiveness = 10
    self.AlignPos.Enabled = false
    self.AlignPos.Parent = self.RootPart
    
    self.AlignRot = Instance.new("AlignOrientation")
    self.AlignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
    self.AlignRot.Attachment0 = self.FlightAttachment
    self.AlignRot.MaxTorque = 100000
    self.AlignRot.Responsiveness = 10
    self.AlignRot.Enabled = false
    self.AlignRot.Parent = self.RootPart
    
    -- Gravity Compensation
    local antiGravity = Instance.new("VectorForce")
    antiGravity.Force = Vector3.new(0, self.RootPart:GetMass() * workspace.Gravity, 0)
    antiGravity.Attachment0 = self.FlightAttachment
    antiGravity.Enabled = false
    antiGravity.Parent = self.RootPart
    self.AntiGravity = antiGravity
    
    self.IsFlying = false
    self.Seat = nil -- Added Seat reference
    
    return self
end

function FlyingMonster:SetOwner(player: Player)
    -- Call Base
    Monster.SetOwner(self, player)
    
    -- Spawn Seat
    if not self.Seat then
        local seat = Instance.new("VehicleSeat")
        seat.Name = "DragonSeat"
        seat.Size = Vector3.new(2, 1, 2)
        seat.Transparency = 1
        seat.Parent = self.Model
        
        local weld = Instance.new("Weld")
        weld.Part0 = self.RootPart
        weld.Part1 = seat
        weld.C0 = CFrame.new(0, 4, 0) -- Sit on back
        weld.Parent = seat
        
        self.Seat = seat
        
        -- Override Control Loop
        task.spawn(function()
            while self.Model and self.Model.Parent do
                if self.Seat.Occupant then
                    self:MountLoop()
                end
                task.wait()
            end
        end)
    end
end

function FlyingMonster:MountLoop()
    -- Mount loop is now primarily handled by client-side DragonControls
    -- Server just maintains the mount state and flying flag
    -- Client sets network ownership and controls physics directly via LinearVelocity/AngularVelocity
    
    if not self.IsFlying then 
        self:SetFlying(true) 
    end
    
    -- Keep dragon awake and in physics state while mounted
    if self.Humanoid then
        self.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
end

function FlyingMonster:Follow(targetPart: BasePart?)
    -- Disable AI if Mounted
    if self.Seat and self.Seat.Occupant then
        return
    end

    self.Target = targetPart
    
    if not targetPart then
        self:SetFlying(false)
        self.Humanoid:MoveTo(self.RootPart.Position)
        return
    end
    
    local distance = (targetPart.Position - self.RootPart.Position).Magnitude
    
    -- Flight Logic Threshold
    if distance > 20 then
        if not self.IsFlying then
            self:SetFlying(true)
        end
        
        -- Fly towards target, but hover above
        local targetPos = targetPart.Position + Vector3.new(0, 15, 0)
        self.AlignPos.Position = targetPos
        
        -- Look at target
        self.AlignRot.CFrame = CFrame.lookAt(self.RootPart.Position, targetPart.Position)
    else
        -- Land and walk
        if self.IsFlying then
            self:SetFlying(false)
        end
        -- Use base walk logic
        Monster.Follow(self, targetPart)
    end
end

function FlyingMonster:SetFlying(flying: boolean)
    self.IsFlying = flying
    self.AlignPos.Enabled = flying
    self.AlignRot.Enabled = flying
    self.AntiGravity.Enabled = flying
    
    if flying then
        self.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        -- Visuals: unfold wings? (animation trigger placeholder)
    else
        self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

return FlyingMonster
