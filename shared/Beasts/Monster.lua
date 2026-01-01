--!strict
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local Monster = {}
Monster.__index = Monster

export type Monster = {
    Model: Model,
    Humanoid: Humanoid,
    RootPart: BasePart,
    Owner: Player?,
    Trust: number,
    Stats: {
        Health: number,
        Speed: number,
    },
    Target: BasePart?,
    _janitor: {any} -- Simple cleanup table
}

function Monster.new(model: Model)
    local self = setmetatable({}, Monster)
    
    self.Model = model
    self.Humanoid = model:FindFirstChildWhichIsA("Humanoid") or model:WaitForChild("Humanoid")
    self.RootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    self.Owner = nil
    self.Trust = 0
    self.Stats = {
        Health = 100,
        Speed = 16
    }
    
    self.Target = nil
    self._janitor = {}
    
    -- Initialize
    self.Humanoid.WalkSpeed = self.Stats.Speed
    
    return self
end

function Monster:Follow(targetPart: BasePart?)
    self.Target = targetPart
    
    if not targetPart then
        self.Humanoid:MoveTo(self.RootPart.Position) -- Stop
        return
    end
    
    -- Basic Pathfinding
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(self.RootPart.Position, targetPart.Position)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        -- Move to first waypoint after start
        if waypoints[2] then
            self.Humanoid:MoveTo(waypoints[2].Position)
        else
            self.Humanoid:MoveTo(targetPart.Position)
        end
    else
        -- Direct line fallback
        self.Humanoid:MoveTo(targetPart.Position)
    end
end

function Monster:Eat(item: BasePart)
    if not item then return end
    
    -- Visual: Face item
    self.RootPart.CFrame = CFrame.lookAt(self.RootPart.Position, Vector3.new(item.Position.X, self.RootPart.Position.Y, item.Position.Z))
    
    -- Logic: Increase Trust
    self.Trust = math.min(100, self.Trust + 10)
    print(self.Model.Name .. " ate " .. item.Name .. ". Trust: " .. self.Trust)
    
    item:Destroy()
    
    -- visual jump
    self.Humanoid.Jump = true
end

function Monster:SetOwner(player: Player)
    self.Owner = player
    self.Trust = 100
    print(self.Model.Name .. " is now owned by " .. player.Name)
    
    -- Visual indicator
    local head = self.Model:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.Adornee = head
        billboard.AlwaysOnTop = true
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = player.Name .. "'s Pet"
        text.TextColor3 = Color3.new(0, 1, 0)
        text.TextStrokeTransparency = 0
        text.Parent = billboard
        
        billboard.Parent = head
    end
end

function Monster:Destroy()
    for _, obj in ipairs(self._janitor) do
        if typeof(obj) == "Instance" then 
            obj:Destroy() 
        elseif typeof(obj) == "RBXScriptConnection" then
            obj:Disconnect()
        end
    end
    if self.Model and self.Model.Parent then
        self.Model:Destroy()
    end
end

return Monster
