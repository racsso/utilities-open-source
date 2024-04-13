# Description
A simple lightweight melee raycast module designed to be run on the client. Functions very similarly to other modules like ClientCast or RaycastHitboxV4.
Supports both raycasting via attachments or BlockCasting an object.

# Settings:
```
Object: BasePart - The part that is used as either the parent for the attachments or the object which size and CFrame is used for the BlockCast.
Type: String - The 2 types of raycasting that can be done. "Raycast" uses attachments and "BlockCast" is blockcasting.
RayParams: RaycastParams - The RaycastParams used for all raycasts done by the module.
AttachmentName: String - Attachments with this specefied name are used as raycast points.
Debounce: boolean - If set to true, then whatever is returned in the OnHit function can only be hit once until the raycast hitbox is started or stopped again.
OnHit: function - The function that's called whenever a hit gets validated. Returns the hit character.
```

# Example usage:
```lua
local Character = game.Players.LocalPlayer.Character
local Sword = Character:WaitForChild("Sword") 

local QRaycast = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("QuickRaycast"))

local RaycastHibox: QRaycast.ModuleType = nil
local Debug = true

local MeleeRayParams = RaycastParams.new()
MeleeRayParams.IgnoreWater = true
MeleeRayParams.FilterType = Enum.RaycastFilterType.Include
MeleeRayParams.FilterDescendantsInstances = {workspace.Terrain, workspace.Map, workspace.Characters}


local function OnHitFunction(Character: Model)
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		Humanoid:TakeDamage(10)
	end
end


RaycastHibox = QRaycast.New({
	Object = Sword,
	Type = "Raycast"
	AttachmentName = "DmgPoint",
	RayParams = MeleeRayParams,
	Debounce = true,
	OnHit = OnHitFunction,
})

if Debug then
	RaycastHibox.EnableDebug()
end


local function StartSwing()
	RaycastHibox.Start()
end

local function StopSwing()
	RaycastHibox.Stop()
end


Sword.Destroying:Once(function()
	RaycastHibox.Destroy()
end)
```
