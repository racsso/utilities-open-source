This module is desgined for scheduling and automatically un-scheduling threads that execute specefic functions or adjust values of instances.

I mostly use it for cooldowns that don't need to avalible to other scripts.


Example usage:

```lua
local Scheduler = require(game.ReplicatedStorage:WaitForChild("Scheduler"))()
local DashCD = false

local DashCDTime = 1


function Dash()
	if not DashCD then
		Scheduler.ScheduleIdentifier("Dash", DashCDTime, function()
			DashCD = false
		end)
		
		DashCD = true
		-- Do the dash
	else
		-- Dash is on cooldown :<
	end
end


function Stunned()
	-- This will automatically cancel the other sheduled thread in the Dash() function
	Scheduler.ScheduleIdentifier("Dash", 2, function()
		DashCD = false
	end)	
	
	
end



game.UserInputService.InputBegan:Connect(function(Input: InputObject)
	if Input.KeyCode == Enum.KeyCode.C then
		Dash()
	end
end)
```
