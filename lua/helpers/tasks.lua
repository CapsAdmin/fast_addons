tasks = {}

tasks.Registered = {}
tasks.__hooks = {}

function tasks.Register(TASK)
	tasks.Registered[TASK.Name] = TASK
end

do
	local CHAIN = {}
	CHAIN.__index = CHAIN

	CHAIN.Tasks = {}
	CHAIN.Index = 1

	function CHAIN:Add(name, ...)
		local obj = tasks.CreateTask(name)
		obj.args = {...}
		obj.Chain = self
		table.insert(self.Tasks, obj)
	end

	function CHAIN:Think()
		local task = self.Tasks[self.Index]
		if task then
			local done, msg = task:Think()

			if not task.started then
				task:OnStart(unpack(task.args))
				task.started = true
			end

			if msg then
				self:OnMessage(task.Name, msg)
			end

			if done or task.done then
				task:RemoveHooks()
				task:OnEnd()
				self.Index = self.Index + 1
			end
		else
			self:OnEnd()
			return true
		end
	end

	function CHAIN:SetIndex(num)
		self:Stop()
		self.Index = num
		self:Think()
		self:Start()
	end

	function CHAIN:Start()
		tasks.__hooks.Think = self.hook_id

		hook.Add("Think", self.hook_id, function()
			if self:Think() then
				hook.Remove("Think", self.hook_id)
				self:OnEnd()
			end
		end)
	end

	function CHAIN:Stop()
		local task = self.Tasks[self.Index]
		if task then
			task:RemoveHooks()
			task.started = false
		end

		hook.Remove("Think", self.hook_id)
	end

	function CHAIN:OnEnd()

	end

	function CHAIN:OnMessage(name, msg)

	end

	tasks.ChainMeta = CHAIN
end

do
	local TASK = {}
	TASK.__index = TASK

	TASK.Name = "base"
	TASK.Hooks = {}

	function TASK:Hook(event)
		tasks.__hooks[event] = tostring(self)
		hook.Add(event, "task_" .. tostring(self), function(...) return self[event](self, ...) end)
		self.Hooks[event] = true
	end

	function TASK:RemoveHooks()
		for event in pairs(self.Hooks) do
			hook.Remove(event, "task_" .. tostring(self))
		end
	end

	function TASK:OnStart(...)

	end

	function TASK:OnEnd()

		return nil
	end

	function TASK:Think()

		--return true
	end

	function TASK:Done()
		self.done = true
	end

	tasks.TaskMeta = TASK
end

function tasks.CreateTask(name)
	local meta = table.Merge(table.Copy(tasks.TaskMeta), table.Copy(tasks.Registered[name]))
	local obj = setmetatable({}, meta)
	return obj
end

function tasks.CreateChain()
	local obj = setmetatable({}, tasks.ChainMeta)
	obj.hook_id = "chain_think_" .. tostring(self)
	return obj
end

function tasks.Panic()
	for key, val in pairs(self.__hooks) do
		hook.Remove(key, val)
		self.__hooks[key] = nil
	end
end