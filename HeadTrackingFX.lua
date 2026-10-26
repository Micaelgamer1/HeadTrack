-- HeadTrackingFX.lua (v2)
-- Cabeça acompanha a câmera (R6 + R15), com um "ponto de vista" soldado à cabeça
-- pra tirar a câmera de dentro do crânio em primeira pessoa (em vez de forçar a
-- cabeça visível, que foi o que causou o bug de "ver o interior").

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local LIMITS = {
	R6 = { pitchUp = 50, pitchDown = 60, yaw = 70 },
	R15 = { pitchUp = 50, pitchDown = 60, yaw = 80 },
}
local SMOOTH_SPEED = 12

-- Deslocamento do ponto de vista em relação ao centro da cabeça: pra cima e pra frente,
-- o suficiente pra câmera ficar do lado de fora do crânio. Ajuste se ainda cortar.
local POV_OFFSET = CFrame.new(0, 0.35, -0.4)

local neck, originalC0, rootPart, rigLimits, povPart
local currentPitch, currentYaw = 0, 0

local function makePovPart(head)
	local part = Instance.new("Part")
	part.Name = "Pov"
	part.Size = Vector3.new(0.05, 0.05, 0.05)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = head.CFrame * POV_OFFSET

	local weld = Instance.new("Weld")
	weld.Name = "PovHolder"
	weld.Part0 = head
	weld.Part1 = part
	weld.C0 = POV_OFFSET
	weld.Parent = part

	part.Parent = head
	return part
end

local function onCharacterAdded(character)
	neck, originalC0, rootPart, rigLimits, povPart = nil, nil, nil, nil, nil
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
	povPart = makePovPart(head)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

RunService:BindToRenderStep("HeadTrackingFX", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not (neck and neck.Parent and rootPart and rootPart.Parent and rigLimits and povPart and povPart.Parent) then
		return
	end

	-- Câmera mira o "Pov" em vez da cabeça/Humanoid padrão
	camera.CameraSubject = povPart

	local camPitch, camYaw = camera.CFrame:ToOrientation()
	local _, bodyYaw = rootPart.CFrame:ToOrientation()

	local targetYaw = math.clamp(camYaw - bodyYaw, -math.rad(rigLimits.yaw), math.rad(rigLimits.yaw))
	local targetPitch = math.clamp(camPitch, -math.rad(rigLimits.pitchDown), math.rad(rigLimits.pitchUp))

	local alpha = math.min(SMOOTH_SPEED * dt, 1)
	currentYaw += (targetYaw - currentYaw) * alpha
	currentPitch += (targetPitch - currentPitch) * alpha

	-- Se a cabeça inclinar pro lado errado, inverte o sinal de currentPitch e/ou currentYaw aqui embaixo
	neck.C0 = originalC0 * CFrame.Angles(currentPitch, currentYaw, 0)
end)
