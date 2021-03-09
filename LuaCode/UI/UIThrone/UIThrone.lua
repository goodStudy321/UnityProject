UIThrone = Super:New {Name = "UIThrone"}

local My = UIThrone
local ThMgr = ThroneMgr

local pre = "UI/UIThrone/UIThrone"

--基础模块
My.basic = require(pre .. "Basic")

--进阶模块
My.step = require(pre .. "Step")

--分解模块
My.compose = require(pre .. "Compose")

function My:Init(root)
	self.root = root
	self.go = root.gameObject
	local des, CG, UL = self.Name, ComTool.Get, UILabel
	self.ftLbl = CG(UL, root, "ft", des)
	self.nameLbl = CG(UL, root, "nameBg/name", des)
	self.stepLbl = CG(UL, root, "stepBg/step", des)

	local USBC = UITool.SetBtnClick

	local SetSub = UIMisc.SetSub
	SetSub(self, self.step, "step")
	SetSub(self, self.compose, "compose")
	SetSub(self, self.basic, "base")
	self.step.db = ThroneMgr
	--当前模块
	self.cur = baisc
	self:SetEvent("Add")
end

function My:SetEvent(fn)
	ThMgr.eRespCompose[fn](ThMgr.eRespCompose, self.OnComposeInfo, self)
end

--道具分解返回
function My:OnComposeInfo()
	self.step:SetPro()
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

--设置等级
function My:SetStep(val)
	self.stepLbl.text = val
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
	self:SetEvent("Remove")
	self.go:SetActive(false)
	self.basic:ResetMod(true)
	if self.cur then
		self.cur:Close()
	end
end

function My:Dispose()
	self:SetEvent("Remove")
	self.cur = nil
	self.step:Dispose()
	self.basic:Dispose()
	self.compose:Dispose()
end
