UISysActBtn = Super:New{Name="UISysActBtn"}
local My = UISysActBtn


function My:Init(acId,go)
	local t = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local name = self.Name
	self.GO = go
	self.actId = acId
	self.Icon = C(UISprite, t, "Icon", name, false)
	self.NameLab = C(UILabel, t, "Label", name, false)
	self.Action = T(t, "Action")
	self.TimerLab = C(UILabel, t, "TimerLab", name, false)
	self.TimerBg = T(t, "TimerLab/Sprite")
	self.Eff = T(t, "Eff")
	local E = UITool.SetLsnrSelf
	E(go, self.ClickBtnForKey, self)
	self:SetEvent("Add")
	self:UpdateInfo()
end

function My:SetEvent(fn)
	-- CopyMgr.eMarryCopyRequest[fn](CopyMgr.eMarryCopyRequest, self.MarryCopyRequest, self)
end

function My:SetGOAc(ac)
	self.GO:SetActive(ac)
end

function My:UpdateInfo()
	local key = self.actId
	key = tostring(key)
	local acInfo = ActiveInfo[key]
	self.NameLab.text = acInfo.name
	self:SetTimeAc(true)
	self.Eff:SetActive(true)
end

function My:SetTimeAc(ac)
	self.TimerLab.gameObject:SetActive(ac)
end

function My:SetTimeLab(time)
	self.TimerLab.text = time
end

function My:ClickBtnForKey(key)
	local aMgr = ActivityMsg
	local key = self.actId
	if key == aMgr.ZXZC then --诛仙战场
        UIArena.OpenArena(4)
    elseif key == aMgr.XFLJ then --仙峰论剑
        UIArena.OpenArena(2)
    elseif key == aMgr.SWDT then--守卫道庭
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyDefendWnd.Name)
        end
	elseif key == aMgr.SSLD then--蜀山论道
		local isOpen = ActivityMsg.ActIsOpen(key)
		if not isOpen then 
			UITip.Error("活动未开启")
			return
		end
        SceneMgr:ReqPreEnter(30006, true, true) 
    elseif key == aMgr.DTDT then--道庭答题
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyAnswerIt.Name)
        end
    elseif key == aMgr.DTSS then--道庭神兽
        if CustomInfo:IsJoinFamily() then
            UIFamilyBossIt:OpenTab(true)
        end
    elseif key == aMgr.XYST then--逍遥神坛
        UIMgr.Open(UITopFightIt.Name)
    elseif key == aMgr.DTDZ then--道庭大战
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyWar.Name)
        end
    elseif key == aMgr.MYBS then --魔域禁地
        UIMgr.Open(UIDemonArea.Name)
    end
end

function My:Dispose()
	self:SetEvent("Remove")
end
