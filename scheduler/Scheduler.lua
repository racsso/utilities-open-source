-- Written by racs(_superFan) https://www.roblox.com/users/3677722857/profile
-- 2024

return function()
	local Current = {}
	
	local function SafeCancel(Thread: thread)
		if Thread and type(Thread) == "thread" then
			task.cancel(Thread)
		end
	end
	
	local FuncTable = {} 
	FuncTable = {
		ScheduleProperty = function(Time: number, Inst: Instance, Property: string, Value: any)
			if not Inst or typeof(Inst) ~= "Instance" then
				error("Instance nil or not an instance.")
			end
			
			if not Current[Inst] then
				Current[Inst] = {}
				
				Inst.Destroying:Once(function()
					if Current[Inst] then
						for _, Thread: thread in pairs(Current[Inst]) do
							SafeCancel(Thread)
							Thread = nil
						end
						
						Current[Inst] = nil
					end
				end)
			end
			
			local CurTable = Current[Inst]
			if not CurTable[Property] then
				CurTable[Property] = false
			else
				SafeCancel(CurTable[Property])
			end
			
			CurTable[Property] = task.delay(Time or 0, function()
				Inst[Property] = Value
			end)
		end,
		
		UnscheduleProperty = function(Inst: Instance, Property: string)
			if not Inst or typeof(Inst) ~= "Instance" then
				error("Instance nil or not an instance.")
			end

			if Current[Inst] then
				SafeCancel(Current[Inst][Property])
			end			
		end,
		
		ScheduleIdentifier = function(ID: string, Time: number, Func: () -> ())
			if not ID then
				error("ID is nil")
			end
			if not Func then
				error("Function is nil")
			end
			
			SafeCancel(Current[ID])

			
			Current[ID] = task.delay(Time or 0, Func)
		end,
		
		UnscheduleIdentifier = function(ID: string)
			if not ID then
				error("ID is nil")
			end
			
			SafeCancel(Current[ID])
		end,
		
		UnscheduleAll = function()
			for ID: string | Instance, Table: {} in pairs(Current) do
				if type(ID) == "string" then
					SafeCancel(Current[ID])
				else
					for Property, _ in pairs(Table) do
						SafeCancel(Current[ID][Property])
					end
				end
			end
			
			table.clear(Current)
		end,
		
	}
	
	
	return FuncTable
end
