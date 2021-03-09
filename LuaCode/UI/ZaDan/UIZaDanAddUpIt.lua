--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-10 15:39:37
--=========================================================================

UIZaDanAddUpIt = Super:New{ Name = "UIZaDanAddUpIt" }

local My = UIZaDanAddUpIt

function My:Ctor()
    --索引:id, v:gameObject
    self.states = {}
end

----BEG PUBLIC

function My:Init(root, cfg)
    self.cfg = cfg
    local des = self.Name
    local USBC ,CG= UITool.SetBtnClick,ComTool.Get
    local TFC= TransTool.FindChild

    self.desLbl = CG(UILabel, root, "des", des)
    self.uiTbl = CG(UITable, root, "tbl", des)

    local notBtnGo = TFC(root, "not", des)
    local getBtnGo = TFC(root, "getBtn", des)
    local getedBtnGo = TFC(root, "getedBtn", des)

    local states = self.states
    states[1] = notBtnGo
    states[2] = getBtnGo
    states[3] = getedBtnGo
    self:SetStateByCfg(cfg)

    USBC(root, "getBtn", des, self.OnClickGetBtn, self)

    self:SetAwards()
    self:SetStateByTime(ZaDanMgr.times)
end

function My:SetStateByTime(tm, max)
    self.desLbl.text = "累计砸蛋" .. tm .. "/" .. self.cfg.cond .. ", 即可领取"
    self:SetStateByCfg(self.cfg)
end


function My:SetStateByCfg(cfg)
    local state = ZaDanMgr:GetRewardState(cfg.id)
    if state == nil then
        iTrace.eError("Loong", "砸蛋没有对应此ID:",cfg.id,"的累加配置")
    else
        self:SetState(state)
    end
end

function My:SetState(state)
    local at = nil
    for i, v in ipairs(self.states) do
        at = (i == state)
        v:SetActive(at)
    end
end
----END PUBLIC

function My:SetAwards()
    if(self.awards == nil ) then self.awards = ObjPool.Get(UIItemsTable) end
    self.awards:Init(self.uiTbl)
    self.awards:Refresh(self.cfg.its,"id", "cnt", "fx", "bd", 0.62)
    
end

function My:OnClickGetBtn()
    ZaDanMgr:ReqGet(self.cfg.id)
end


function My:Dispose()
    self.awards:Dispose()
    ListTool.Clear(self.states)
end


return My