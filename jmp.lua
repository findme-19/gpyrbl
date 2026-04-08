local enabled = true
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F then
        enabled = not enabled
        print("Infinite Jump:", enabled)
    end
end)

UIS.JumpRequest:Connect(function()
    if not enabled then return end
    local char = game.Players.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
