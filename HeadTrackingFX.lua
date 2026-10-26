--==================================================================
-- HeadFollowCamera | R6 + R15 | cabeça e corpo seguem a câmera
-- Só cabeça:      _G.HFC.PesoCorpo = 0
-- Desligar:       _G.HFC.Ativo = false
--==================================================================
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local CFG = {
	Ativo     = true,
	PitchMax  = math.rad(60),   -- limite pra olhar cima/baixo
	YawCabeca = math.rad(35),   -- giro extra da cabeça além do corpo
	YawCorpo  = math.rad(80),   -- limite de torção do corpo
	PesoCorpo = 1.0,            -- 0 = corpo travado | 1 = corpo acompanha
	Suavidade = 0.25,           -- 0.05 lento/fluido .. 1 seco
}
_G.HFC = CFG

local rig, conn = {}, nil
local curPitch, curYaw = 0, 0

local function acharMotor(char, nome)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == nome then return d end
	end
end

local function montar(char)
	rig = {}
	local pescoco = acharMotor(char, "Neck")
	if not pescoco then return false end
	rig.neck     = pescoco
	rig.neckBase = pescoco.C0        -- guarda a pose original UMA vez
	-- R15: Waist (LowerTorso->UpperTorso) | R6: RootJoint (HRP->Torso)
	local corpo = acharMotor(char, "Waist") or acharMotor(char, "RootJoint")
	if corpo then
		rig.corpo     = corpo
		rig.corpoBase = corpo.C0
	end
	curPitch, curYaw = 0, 0
	return true
end

local function passo()
	if not CFG.Ativo or not rig.neck then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not hrp or not camera then return end

	-- direção da câmera NO ESPAÇO DO PERSONAGEM
	local rx, ry = hrp.CFrame:ToObjectSpace(camera.CFrame):ToEulerAnglesYXZ()

	local alvoPitch = math.clamp(rx, -CFG.PitchMax, CFG.PitchMax)
	local alvoYaw   = math.clamp(ry, -CFG.YawCorpo, CFG.YawCorpo)

	local a = math.clamp(CFG.Suavidade, 0.02, 1)
	curPitch += (alvoPitch - curPitch) * a
	curYaw   += (alvoYaw   - curYaw)   * a

	local corpoYaw = 0
	if rig.corpo then
		corpoYaw = curYaw * CFG.PesoCorpo
		rig.corpo.C0 = rig.corpoBase * CFrame.fromEulerAnglesYXZ(0, corpoYaw, 0)
	end

	local yawCabeca = math.clamp(curYaw - corpoYaw, -CFG.YawCabeca, CFG.YawCabeca)
	rig.neck.C0 = rig.neckBase * CFrame.fromEulerAnglesYXZ(curPitch, yawCabeca, 0)
end

local function iniciar(char)
	if not char then return end
	char:WaitForChild("Head", 10)
	task.wait(0.2)
	if montar(char) then
		if conn then conn:Disconnect() end
		conn = RunService.RenderStepped:Connect(passo)
	end
end

iniciar(player.Character)
player.CharacterAdded:Connect(iniciar)
