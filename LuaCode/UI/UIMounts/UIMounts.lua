--[[
	authors 	:Loong
 	date    	:2017-08-17 19:57:59
 	descrition 	:
--]]

UIMounts = Super:New {Name = "UIMounts"}

local My = UIMounts

local pre = "UI/UIMounts/UIMounts"

--皮肤模块
--My.skin = require(pre .. "Skin")

--基础模块
My.basic = require(pre .. "Basic")

--进阶模块
My.step = require(pre .. "Step")

function My:Init(root)
	self.root = root
	self.go = root.gameObject
	local des, CG, UL = self.Name, ComTool.Get, UILabel
	self.ftLbl = CG(UL, root, "ft", des)
	self.nameLbl = CG(UL, root, "nameBg/name", des)
	self.stepLbl = CG(UL, root, "stepBg/step", des)

	local USBC = UITool.SetBtnClick

	local SetSub = UIMisc.SetSub
	--SetSub(self, self.skin, "skin")
	SetSub(self, self.basic, "base")
	self.step.db = MountsMgr
	SetSub(self, self.step, "step")
	--当前模块
	self.cur = baisc
end

function My:Update()
	self.basic:Update()
end

--设置战斗力
function My:SetFight(val)
	self.ftLbl.text = tostring(val)
end

--设置名称
function My:SetName(name)
	self.nameLbl.text = name
end

--设置阶数
function My:SetStep(val)
	self.stepLbl.text = self:ChangeStepShow(val)
end

function My:ChangeStepShow(step)
	step = tonumber(step)
	if step == 1 then
		return "一"
	elseif step == 2 then
		return "二"
	elseif step == 3 then
		return "三"
	elseif step == 4 then
		return "四"
	elseif step == 5 then
		return "五"
	elseif step == 6 then
		return "六"
	elseif step == 7 then
		return "七"
	elseif step == 8 then
		return "八"
	elseif step == 9 then
		return "九"
	elseif step == 10 then
		return "十"
	end
end

--切换模块信息
function My:Switch(cur)
	if cur == nil then return end
	if cur == self.cur then return end
	self.cur:Close()
	cur:Open()
	cur:Refresh()
	self.cur = cur
end

function My:Open()
	self.go:SetActive(true)
	self.cur = self.basic
	self.basic:Open()
end

function My:Close()
	self.go:SetActive(false)
	if self.cur then
		self.cur:Close()
	end
end

function My:Dispose()
	self.cur = nil
	self.step:Dispose()
	--self.skin:Dispose()
	self.basic:Dispose()
end
