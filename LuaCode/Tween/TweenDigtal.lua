--[[
	AU:Loong
	TM:2017.7.20
	BG:数字插值
--]]
local Time = UnityEngine.Time
TweenDigtal = Super:New{Name="TweenDigtal"}
local My = TweenDigtal

My.last = 0

My.current = 0

My.count = 0

My.running = false

My.label = nil

--开始
function My:Start()
	self.count = 0
	self.running = true
end

--更新
function My:Update()
	if not self.running then return end
	if self.label == nil then return end
	self.count = self.count + Time.deltaTime
	local t = self.count
	if t < 1 then
		local val = self.last + (self.current - self.last) * t
		local tVal = math.ceil(val)
		self.label.text = tostring(tVal)
	else
		self.label.text = tostring(self.current)
		self.last = self.current
		self.running = false
		self.count = 0
	end
end

--释放
function My:Dispose()
	self.last = 0
	self.count = 0
	self.current = 0
	self.label = nil
	self.running = false
end
