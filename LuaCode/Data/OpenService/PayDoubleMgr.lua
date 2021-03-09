PayDoubleMgr = Super:New{Name = "PayDoubleMgr"}
local My = PayDoubleMgr

function My:Init()
    self:SetLsner(ProtoLsnr.Add)
    self:SetLn("Add")
    self.isRed = true
end

function My:SetLsner(fun)
    -- fun(23060,self.ResPrayInfo,self)
    -- fun(23062,self.ResRewardExp,self) --上线推送离线经验
    -- fun(23058,self.ResReward,self)
end
function My:SetLn(func)
    NewActivMgr.eUpActivInfo[func](NewActivMgr.eUpActivInfo, self.RespUpActivState, self)
end

function My:RespUpActivState(actionId)
    local id = actionId
    local sysId = ActivityMgr.SCBS
    local isReds = self.isRed
    local isOpen = self:IsOpen()
    if id and id == 2000 and isOpen and isReds then
        self.isRed = false
        PayMulMgr:UpAction(1,isReds)
    elseif id == nil and isOpen then
        self.isRed = false
        PayMulMgr:UpAction(1,isReds)
    end
end

function My:GetPayIds()
    local tab = {}
    for i = 1,#RechargeCfg do
        local info = RechargeCfg[i]
        local type = info.giftType
        if type == 4 then
            table.insert(tab,info)
        end
    end
    return tab
end

function My:IsOpen()
    -- local cfg = XsActiveCfg["2000"]
    -- local id = 1004 --临时用首充代替
    -- if cfg == nil then
    --     id = 1004
    -- else
    --     id = cfg.id
    -- end
    local isOpen = NewActivMgr:ActivIsOpen(2000) --首充倍送是否开启
    return isOpen
end

function My:Clear()
    
end

function My:Dispose()
    self.isRed = true
    self:SetLn("Remove")
end

return My