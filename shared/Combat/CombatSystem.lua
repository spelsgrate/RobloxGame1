--!strict
local Debris = game:GetService("Debris")

local CombatSystem = {}

function CombatSystem:ApplyDamage(character: Model, amount: number, source: Instance?)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    
    -- Apply damage
    humanoid.Health = math.max(0, humanoid.Health - amount)
    
    -- Visual feedback - red flash
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if head then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 1
        highlight.Parent = character
        Debris:AddItem(highlight, 0.2)
    end
    
    print(character.Name .. " took " .. amount .. " damage (HP: " .. math.floor(humanoid.Health) .. ")")
end

function CombatSystem:Heal(character: Model, amount: number)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    
    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
    
    -- Visual feedback - green flash
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if head then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.new(0, 1, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 1
        highlight.Parent = character
        Debris:AddItem(highlight, 0.2)
    end
end

function CombatSystem:CreateHealthBar(character: Model)
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not head then
        return
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HealthBar"
    billboard.Size = UDim2.new(4, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
    bar.BackgroundColor3 = Color3.new(0, 1, 0)
    bar.BorderSizePixel = 0
    bar.Parent = background
    
    -- Update bar on health change
    humanoid.HealthChanged:Connect(function(health)
        local percent = health / humanoid.MaxHealth
        bar.Size = UDim2.new(percent, 0, 1, 0)
        
        -- Color code: green -> yellow -> red
        if percent > 0.5 then
            bar.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
        elseif percent > 0.25 then
            bar.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            bar.BackgroundColor3 = Color3.new(1, 0, 0) -- Red
        end
    end)
end

return CombatSystem
