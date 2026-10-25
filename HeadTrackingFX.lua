-- HeadTrackingFX.lua
-- Cabeça do personagem acompanha a câmera (R6 + R15), ficando visível mesmo em primeira pessoa.
-- Ponto de partida pra ajustar ângulo/suavização até bater com o jogo original.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Limites de rotação em graus. R15 costuma aguentar um giro de pescoço um pouco maior.
local LIMITS = {
	R6 = { pitchUp = 50, pitchDown = 60, yaw = 70 },
	R15 = { pitchUp = 50, pitchDown = 60, yaw = 80 },
}

local SMOOTH_SPEED = 12 -- maior = cabeça "alcança" a câmera mais rápido (menos suave)

local neck, originalC0, rootPart, rigLimits
local currentPitch, currentYaw = 0, 0

local function onCharacterAdded(character)
	neck, originalC0, rootPart, rigLimits = nil, nil, nil, nil
	currentPitch, currentYaw = 0, 0

	local humanoid = character:WaitForChild("Humanoid")
	local head = character:WaitForChild("Head")
	rootPart = character:WaitForChild("HumanoidRootPart")
	neck = head:FindFirstChild("Neck")
	if not neck then
		warn("HeadTrackingFX: Neck não encontrado nesse personagem")
		return
	end

	originalC0 = neck.C0
	rigLimits = (humanoid.RigType == Enum.HumanoidRigType.R15) and LIMITS.R15 or LIMITS.R6
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

-- Roda logo depois do script de câmera padrão do Roblox, pra:
-- 1) usar a CFrame de câmera já atualizada nesse frame
-- 2) sobrescrever a transparência que o jogo põe na cabeça em primeira pessoa
RunService:BindToRenderStep("HeadTrackingFX", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not (neck and neck.Parent and rootPart and rootPart.Parent and rigLimits) then
		return
	end

	local head = neck.Parent
	head.LocalTransparencyModifier = 0 -- mantém a cabeça visível em 1ª pessoa

	local camPitch, camYaw = camera.CFrame:ToOrientation()
	local _, bodyYaw = rootPart.CFrame:ToOrientation()

	-- Yaw relativo ao corpo (não ao mundo), senão a cabeça "roda" junto com o personagem inteiro
	local targetYaw = math.clamp(camYaw - bodyYaw, -math.rad(rigLimits.yaw), math.rad(rigLimits.yaw))
	local targetPitch = math.clamp(camPitch, -math.rad(rigLimits.pitchDown), math.rad(rigLimits.pitchUp))

	local alpha = math.min(SMOOTH_SPEED * dt, 1)
	currentYaw += (targetYaw - currentYaw) * alpha
	currentPitch += (targetPitch - currentPitch) * alpha

	-- Se a cabeça inclinar pro lado errado, inverte o sinal de currentPitch e/ou currentYaw aqui embaixo
	neck.C0 = originalC0 * CFrame.Angles(currentPitch, currentYaw, 0)
end)
