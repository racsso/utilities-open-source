local RunService = game:GetService("RunService")

type Settings = {
	Object: BasePart, 
	AttachmentName: string,
	RayParams: RaycastParams,
	Type: string,
	Debounce: boolean,
	OnHit: (Char: Model) -> (),
	Validate: (HitPart: BasePart) -> ()
}

export type ModuleType = {
	Running: boolean,
	Object: BasePart,
	
	RayParams: RaycastParams,
	
	OnHit: (Humanoid) -> (),
	Validate: (HitPart: BasePart) -> (),

	Start: () -> (),
	Stop: () -> (),
	Destroy: () -> (),
	EnableDebug: () -> (),
	DisableDebug: () -> ()
}

return {New = function(Settings: Settings): ModuleType
	local Module = {}	
	local Attachments = {}
	local BreakConnnections = {}
	local ToRemove = {}
	local DebugTrails = {}
	local AlreadyHit = {}
	local Interpolation = Settings.Interpolation
	
	local CastConnection: RBXScriptConnection = nil
	
	Module.Running = false
	Module.Type = Settings.Type or "Raycast"
	Module.Object = Settings.Object
	Module.OnHit = Settings.OnHit
	Module.Debounce = Settings.Debounce or true
	
	Module._DebugEnabled = false
	
	
	
	if not Settings.RayParams then
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.IgnoreWater = true
		Params.FilterDescendantsInstances = {}
		
		Module.RayParams = Params
	else
		Module.RayParams = Settings.RayParams
	end
	
	Module.Validate = Settings.Validate or function(HitPart: BasePart)
		if HitPart then
			local Model = HitPart:FindFirstAncestorOfClass("Model")
			if Model and Model:FindFirstChildOfClass("Humanoid") then
				return Model
			end
		end
		
		return nil
	end
	
	
	local function SafeDC(Connection: RBXScriptConnection | {})		
		if type(Connection) == "table" then
			for _, TCon in pairs(Connection) do
				SafeDC(TCon)
			end
		else
			if Connection and typeof(Connection) == "RBXScriptConnection" then
				Connection:Disconnect()
			end
		end
	end
	
	local function Process(Inst: Instance)
		if Inst and Inst:IsA("Attachment") and Inst.Name == (Settings.AttachmentName or "DmgPoint") then
			table.insert(Attachments, Inst)
		end
	end
	
	for _, Obj in pairs(Module.Object:GetChildren()) do
		Process(Obj)
	end
	
	table.insert(BreakConnnections, Module.Object.ChildAdded:Connect(Process))
	
	local function CreateDebug(Attachment: Attachment)
		local Point0 = Instance.new("Attachment", Attachment)
		Point0.Name = "DebugAttachment0"
		Point0.Position = Vector3.new(-.025, 0, 0)
		
		local Point1 = Instance.new("Attachment", Attachment)
		Point1.Name = "DebugAttachment1"
		Point1.Position = Vector3.new(.025, 0, 0)
		
		local Trail = Instance.new("Trail", Attachment)
		Trail.Attachment0 = Point0
		Trail.Attachment1 = Point1
		Trail.MinLength = 0
		Trail.MaxLength = 100000
		Trail.LightInfluence = 0
		Trail.LightEmission = 1
		Trail.Lifetime = .3
		Trail.FaceCamera = true
		Trail.Color = ColorSequence.new(Color3.new(1,0,0))
		Trail.Transparency = NumberSequence.new(0)
		
		table.insert(ToRemove, Point0)
		table.insert(ToRemove, Point1)
		table.insert(ToRemove, Trail)
		
		DebugTrails[Attachment] = Trail
	end
	
	local function SetTrails(Bool)
		for _, Trail: Trail in pairs(DebugTrails) do
			Trail.Enabled = Bool
		end
	end

	Module.EnableDebug = function()
		Module._DebugEnabled = true
	end

	Module.DisableDebug = function()
		Module._DebugEnabled = false

		SetTrails(false)
	end

	Module.Start = function()
		SafeDC(CastConnection)
		
		Module.Running = true
		
		table.clear(AlreadyHit)
		
		local LastPositions = {}

		if Module._DebugEnabled and not Interpolation then
			if DebugTrails == {} then
				for _, Attachment in pairs(Attachments) do
					CreateDebug(Attachment)
				end	
			end

			for _, Attachment in pairs(Attachments) do
				if not DebugTrails[Attachment] then
					CreateDebug(Attachment)
				end

				local Trail = DebugTrails[Attachment]
				Trail.Enabled = true
			end
		end
		
		local PointsReached = 0
		local LastObjCF = Module.Object.CFrame

	
		local function CreateRays(Start: CFrame, End: CFrame)
			local function ProcessRay(NewRay: RaycastResult)
				if NewRay and NewRay.Instance then
					local GetPart = Module.Validate(NewRay.Instance)
					if GetPart and not (Module.Debounce and AlreadyHit[GetPart]) then
						if Module.Debounce then
							AlreadyHit[GetPart] = true
						end
						
						Module.OnHit(GetPart)
					end
				end
			end
			
			if Module._DebugEnabled then
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.Parent = workspace.Terrain
				p.Color = Color3.new(1,0,0) 
				p.Transparency = .5
				p.Material = Enum.Material.Neon
				game.Debris:AddItem(p, .5)		
				
				if Module.Type == "BlockCast" then
					p.Size = Module.Object.Size
					p.CFrame = Start
				else
					for _, Trail: Trail in pairs(DebugTrails) do
						Trail.Enabled = true
					end
				end
			
				if Module.Type == "BlockCast" then					
					ProcessRay(workspace:Blockcast(Start, Module.Object.Size, End.Position - Start.Position, Module.RayParams))
				else
					for _, Attachment: Attachment in pairs(Attachments) do
						local Start = (Start * Attachment.CFrame).Position
						local End = (End * Attachment.CFrame).Position

						ProcessRay(workspace:Raycast(Start, End - Start, Module.RayParams))
					end	
				end
			end
		end
	
	
		CastConnection = RunService.RenderStepped:Connect(function(DT)
			if Module.Object then
				PointsReached += 1 
				
				local CurObjCF = Module.Object.CFrame
				
				if LastObjCF ~= CurObjCF then
					CreateRays(LastObjCF, CurObjCF)
				end					
			
							
				LastObjCF = CurObjCF
			end
		end)
	end
	
	Module.Stop = function()
		SafeDC(CastConnection)

		SetTrails(false)
		
		table.clear(AlreadyHit)
		
		Module.Running = false
	end

	Module.Destroy = function()
		if Module and Module.Running then
			Module.Stop()
		end
		
		table.clear(DebugTrails)
		table.clear(AlreadyHit)

		for _, Obj: Instance in pairs(ToRemove) do
			Obj:Destroy()
		end
		
		SafeDC(BreakConnnections)
		
		Module = nil
	end

	return Module
end}
