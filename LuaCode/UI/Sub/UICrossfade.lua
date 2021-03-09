--[[
	AU:Loong
	TM:2017.6.9
	BG:描述
--]]

UICrossfade = UIBase:New{Name = "UICrossfade"}

local My = UICrossfade

--调用结束回调
function My:CbFunc()
	My:Close()
	local cb = My.callback
	if cb ~= nil then
		cb() ;cb = nil
	end
end

function My:InitCustom()
	local go = self.gbj
	local root = self.root
	local name = self.Name
	local CG = ComTool.Get
	self.tPlay = CG(UIPlayTween, root, "bg", name)
	self.titleLbl = CG(UILabel, root, "msg", name)
	self.titleLbl.text = ""
	local arr = go:GetComponentsInChildren(typeof(TweenAlpha))
	--淡入
	self.tAlpha1 = arr[0]
	--淡出
	self.tAlpha2 = arr[1]
	self.tAlpha1.from = 0
	self.tAlpha1.to = 1
	self.tAlpha2.from = 1
	self.tAlpha2.to = 0
	UITool.SetTex(root, "bg", TexTool.Black, name)
	local ED = EventDelegate
	ED.Add(self.tPlay.onFinished, ED.Callback(self.CbFunc, self))
	self.timer = ObjPool.Get(iTimer)
end

function My:Start(dur, blackDur, cb)
	self.tAlpha1.duration = dur
	self.tAlpha2.duration = dur
	self.tAlpha2.delay = dur + blackDur
	if type(cb) == "function" then
		self.callback = cb
	end
	self.tPlay:Play(true)
end

function My:StartSubTitle(beg, dur, msg)
	if(type(msg) ~= "string") then return end
	if beg < 0.01 then
		self.titleLbl.text = msg
	else
		self.msg = msg
		self.subTitleDur = dur
		local timer = self.timer
		timer.seconds = beg
		timer.complete:Add(self.ShowSubTitle, self)
		timer:Start()
	end
end

function My:ShowSubTitle()
	self.titleLbl.text = self.msg
	local timer = self.timer
	timer.complete:Remove(self.ShowSubTitle, self)
	timer.complete:Add(self.ClearSubTitle, self)
	timer.seconds = self.subTitleDur
	timer:Start()
end

function My:ClearSubTitle()
	self.titleLbl.text = ""
	self.timer.complete:Remove(self.ClearSubTitle, self)
end

function My:Stop()
	local timer = self.timer
	timer.complete:Remove(self.ShowSubTitle, self)
	timer.complete:Remove(self.ClearSubTitle, self)
	self.titleLbl.text = ""
end

function My:CanRecords()
	do return false end
end

function My:OpenCustom()
	ActPreviewMgr.eChgUI(self.Name, true)
end

function My:CloseCustom()
	ActPreviewMgr.eChgUI(self.Name, false)
	self:Stop()
end

function My:DisposeCustom()
	self.msg = nil
	if(self.timer) then
		self.timer:AutoToPool()
	end
	self.timer = nil
end



return My
