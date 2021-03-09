--region UIPetPropertyToggle.lua
--Date
--此文件由[HS]创建生成

require("UI/UIPet/UIPetDevourView")

UIPetPropertyToggle = {}
local this = UIPetPropertyToggle
--local PetMgs = PetMessage.instance
--local PetInfoMgr = PetInfoManager.instance

--注册的事件回调函数

function UIPetPropertyToggle:New(go, isActiveCallback ,showSkillTip)
	local name = "UI伙伴属性面板"
	self.gameObject = go
	self.IsActiveCallback = isActiveCallback
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Exp = C(UILabel, trans, "EXP", name, false)
	self.Slider = C(UISlider, trans, "Slider", name, false)
	self.Level = C(UILabel,trans, "Level", name, false)
	self.Btn  = C(UIButton, trans, "Button", name, false)
	self.JingpoBtn = C(UIButton, trans, "Jingpo", name, false)
	self.Property = {}
	self.Property["Attack"] = C(UILabel, trans, "StepProperty/Property1", name, false)
	self.Property["Arp"] = C(UILabel, trans, "StepProperty/Property2", name, false)
	self.Property["Hit"] = C(UILabel, trans, "StepProperty/Property3", name, false)
	self.Property["Crit"] = C(UILabel, trans, "StepProperty/Property4", name, false)
	self.Property["Ignore_def"] = C(UILabel, trans, "StepProperty/Property5", name, false)

	self.DevourView = UIPetDevourView.New(T(trans,"DevourView"), isActiveCallback)
	self.DevourView:Init()

	self.JingpoView = UIPetJingpoView:New(T(trans,"JingPoView"), isActiveCallback)
	self.JingpoView:Init()

	self.SkillView = UIPetSkillScrollView.New(T(trans,"Skill"), showSkillTip)
	self.SkillView:Init()

	self.CurInfo = nil 
	
	self:UpdateData()
	self:InitEvent()
	return this
end

function UIPetPropertyToggle:InitEvent()
	if self.Btn then 
		UIEvent.Get(self.Btn.gameObject).onClick = function(gameObject) self:OnClickBtn(gameObject) end
	end
	if self.JingpoBtn then	
		UIEvent.Get(self.JingpoBtn.gameObject).onClick = function (gameObject) self:OnJingpoBtn(gameObject) end
	end
end

function UIPetPropertyToggle:UpdateData()
	self:UpdateStep()
	self:UpdateLevel()
	self:UpdateExp() 
	self:UpdateSkill()
end

function UIPetPropertyToggle:UpdateStep()
	self.CurInfo = PetTemp[tostring(User.PetID)]
	if not PetMgr.PetLvTemplate then return end
	local atk = PetMgr.PetLvTemplate.atk
	local arm = PetMgr.PetLvTemplate.arm
	local hp = PetMgr.PetLvTemplate.hp
	local def = PetMgr.PetLvTemplate.def
	--local ignore = PetMgr.PetLvTemplate.ignoreDef
	if self.CurInfo then
		atk = atk + self.CurInfo.atk
	end
	--[[
	self.CurInfo = PetInfoMgr:Find(PetMgs.PetID)
	local att = PetMgs.PetLevelInfo.att
	local arp = PetMgs.PetLevelInfo.arp
	local hit = PetMgs.PetLevelInfo.hit
	local crit = PetMgs.PetLevelInfo.crit
	local ignore = PetMgs.PetLevelInfo.ignoreDef
	if info ~= nil then
		att = att + info.att
	end
	]]--
	self:UpdateProperty("Attack",atk)
	self:UpdateProperty("Arp",arm)
	self:UpdateProperty("HP",hp)
	self:UpdateProperty("Defence",def)
	--self:UpdateProperty("Ignore_def",ignore)
end

--更新属性 传入值要tostring()
--table的key string类型
--curPro 当前属性
--nextPro 当前属性
function UIPetPropertyToggle:UpdateProperty(name, curPro)
	if self.Property[name] then self.Property[name].text = tostring(curPro) end
end

function UIPetPropertyToggle:UpdateLevel()
	self.Level.text = tostring(PetMgr.Level)
end

function UIPetPropertyToggle:UpdateExp()
	if PetMgr.LimitExp == nil then 
		PetMgr.LimitExp = 0
	end
	if PetMgr.LimitExp == 0 then 
		self.Exp.text = ""
		self.Slider .value = 1
	else
		self.Exp.text = string.format("%s/%s", PetMgr.Exp, PetMgr.LimitExp)
		self.Slider.value = PetMgr.Exp/(PetMgr.LimitExp * 1.00)
	end
end

function UIPetPropertyToggle:UpdateItemList()
	if self.JingpoView then self.JingpoView:UpdateItemList() end
	if self.DevourView then self.DevourView:UpdateData() end
end

function UIPetPropertyToggle:UpdatePetUseJingpoItem()
	if self.JingpoView then self.JingpoView:UpdateUseCount() end
end

function UIPetPropertyToggle:CreateModel()
	return self.CurInfo
end

function UIPetPropertyToggle:UpdateSkill()
	if self.SkillView then self.SkillView:UpdateData(PetMgr.AllSkillIDList, PetMgr.AllSkillDic, false) end
end

function UIPetPropertyToggle:OnClickBtn(go)
	if self.DevourView then self.DevourView:SetActive(true) end
	if self.IsActiveCallback then self.IsActiveCallback(false) end
end

function UIPetPropertyToggle:OnJingpoBtn(go)
	if self.JingpoView then self.JingpoView:SetActive(true) end
	if self.IsActiveCallback then self.IsActiveCallback(false) end
end

function UIPetPropertyToggle:Dispose()
end
--endregion
