require("Data/Arena/OffLBatInfo")
OffLBat = {Name = "OffLBat"}
local  My = OffLBat;

My.HeadDatas = {};
My.eRefresh = Event();

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    local EM = EventMgr.Add;
    local EH = EventHandler;
    self.OnAddOffLUnit = EH(self.SetHeadInfo, self)
	EM("AddOffLUnit", self.OnAddOffLUnit)
end

function My:SetHeadInfo(roleId,name,ctgry,level,maxHp,fightVal)
    local info = OffLBatInfo:New();
    local rId = tostring(roleId);
    info:InitData(rId,name,ctgry,level,maxHp,fightVal);
    My.HeadDatas[rId] = info;
    My.eRefresh();
end

function My.Clear()
    for k,v in pairs(My.HeadDatas) do
        v = nil;
        My.HeadDatas[k] = nil;
    end
end

function My:Dispose()
    self:Clear();
    My.HeadDatas = nil;
end

return My