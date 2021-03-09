--[[
    首冲按钮
--]]

UIFirstPayBtn = Super:New{Name = "UIFirstPayBtn"}
local My = UIFirstPayBtn

function  My:Init(root)
    self.red = ComTool.Get(UISprite, root, "Action")
    UITool.SetBtnSelf(root, self.OnClick, self, self.Name)
    self:SetLnsr("Add")
    self:InitBtnState()
    self:InitRedState()
end

function My:SetLnsr(func)
    FirstPayMgr.eFirstInfo[func](FirstPayMgr.eFirstInfo, self.RespFirstInfo, self)
    FirstPayMgr.eGetAward[func](FirstPayMgr.eGetAward, self.RespGetAward, self)
end

function My:RespFirstInfo(reward)
    self:InitBtnState()
    self:InitRedState()
end

function My:RespGetAward()
    self:InitBtnState()
    LivenessInfo:RemoveActInfo(1004)
end

function My:InitRedState()
    if FirstPayInfo.isGet==2 then
        self.red.gameObject:SetActive(true)
    else
        self.red.gameObject:SetActive(false)
    end
end

function My:OnClick()
    UIFirstPay:OpenFirsyPay()
end

function My:InitBtnState()
    local actId = ActivityMgr.SC
    if FirstPayInfo.isGet==3 then
        LivenessInfo:RemoveActInfo(1004)
        self:Hide()
    end
end

function My:Hide()
    local k,v = ActivityMgr:Find(ActivityMgr.SC)
    ActivityMgr:Remove(v)
end

function My:Clear()
    
end

function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")    
end

return My