JumpMgr = {Name="JumpMgr"}
local M = JumpMgr

M.eOpenJump = Event()

--name:界面的名字，flag:需要打开的标签页
-- M.JumpDic[1] = {Name = "",Flag = -1}

function M:Init()
    self.JumpDic = {}
    self.isInit = false
    self.eOpenJump:Add(self.OpenJumpTemp, self)
    EventMgr.Add("OnChangeScene", EventHandler(self.ClearJumpDic, self))
end

--name:界面的名字，flag:需要打开的标签页 sec:二级标签页   propId:选中道具id
function M:InitJump(name, flag,sec,propId)
    if name == nil or type(name) ~= "string" then
        iTrace.eError("GS","请检查传入界面的名称")
        return
    end
    if flag == nil then
        flag = -1
    end
    self.isInit = true
    local tempDic = {}
    tempDic.name = name
    tempDic.flag = flag
    tempDic.sec = sec
    tempDic.propId = propId
    table.insert(self.JumpDic,tempDic)
end

function M:OpenJumpTemp()
    self.isInit = false
    self:OpenJump()
end

function M:OpenJump()
    local len = #self.JumpDic
    if len == 0 then
        return
    end
    if self.JumpDic[len].name == nil then
        return
    end
    if self.isInit == true then
        self.isInit = false
        return
    end
    local uiName = self.JumpDic[len].name
    local flagId = self.JumpDic[len].flag
    local sec = self.JumpDic[len].sec
    local propId = self.JumpDic[len].propId
    if uiName == nil or type(uiName) ~= "string" then
        iTrace.eError("GS","请检查传入界面的名称")
        return
    end
    if uiName == UIAdv.Name then
        if sec and propId then
            AdvMgr:OpenBySysID(flagId,sec,propId)
        else
            AdvMgr:OpenBySysID(flagId)
        end
    elseif uiName == UIBenefit.Name then
        UIBenefit:Show(flagId)
    elseif  uiName == UICloudBuy.Name then
        UIMgr.Open(uiName)
    elseif uiName == UIRobbery.Name then
        UIRobbery:OpenRobbery(flagId)
    elseif uiName == UIRankActiv.Name then
        UIRankActiv:OpenTab(flagId)
    elseif uiName == UIRole.Name then
        UIRole.OpenIndex = flagId
        UIMgr.Open(UIRole.Name)
    elseif uiName == UISpiritStrength.Name then
        UISpiritStrength.OpenUIByData()
        -- UIMgr.Open(UISpiritStrength.Name)
    elseif uiName == UISpiritAdv.Name then
        local advData = SpiritGMgr:GetAdvData()
        UISpiritAdv:Show(advData)
    elseif uiName == UITransApp.Name then
        UITransApp.OpenTransApp(flagId,propId)
    elseif uiName == UIWish.Name then
        UIMgr.Open(UIWish.Name)
    elseif uiName == UITimeLimitBuy.Name then
        UIMgr.Open(UITimeLimitBuy.Name)
    elseif uiName == UITimeLimitActiv.Name then
        UITimeLimitActiv:OpenTab(flagId)
    elseif uiName == UISevenInvest.Name then
        UIMgr.Open(UISevenInvest.Name)
    elseif uiName == UIEquip.Name then
        if flagId<1 then flagId=1 end
        EquipMgr.OpenEquip(flagId,sec)
    elseif uiName == UIBossReward.Name then
        UIMgr.Open(uiName)
    elseif uiName == UIBlastFur.Name then
        UIMgr.Open(uiName)
    elseif uiName == UIFamilyMainWnd.Name then
        UIMgr.Open(uiName)
    elseif uiName == UIThroneApp.Name then
        UIMgr.Open(uiName)
    -- elseif uiName == UIFamilyEscort.Name then
    --     UIMgr.Open(uiName)
    -- elseif uiName == UIFamilyMission.Name then
    --     UIMgr.Open(uiName)
    -- elseif uiName == UIFamilyDepotWnd.Name then
    --     UIMgr.Open(uiName)
    else
        UITabMgr.OpenByIdx(uiName, flagId)
    end

    self.JumpDic[len].name = nil
    self.JumpDic[len].flag = nil
    table.remove(self.JumpDic,len)
end

function M:ClearJumpDic()
    self:Clear()
end

function M:Clear()
    if self.JumpDic then
        while #self.JumpDic > 0 do
            local len = #self.JumpDic
            self.JumpDic[len].name = nil
            self.JumpDic[len].flag = nil
			table.remove(self.JumpDic, len)
		end
	end
end

function M:Dispose()	
    -- self.eOpenJump:Remove(self.OpenJumpTemp, self)
    -- self:Clear()
end

return M
