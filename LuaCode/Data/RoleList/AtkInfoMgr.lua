require("Data/RoleList/AttackerInfo");
AtkInfoMgr = {Name = "AtkInfoMgr"}
local My = AtkInfoMgr;
local BBMgr = BossBatMgr.instance;
--攻击者列表(攻击玩家自己的目标单位)
My.atkList = {}
My.eUpdateAtk = Event();
My.eSelfDead = Event();
--改变攻击目标事件
My.eChgTarget = Event();

--当前选择目标Id
My.curSelectId = "0"

--初始化
function My:Init()
    self:AddLsnr();
end

--添加监听
function My:AddLsnr()
    local EH = EventHandler;
    local EM = EventMgr.Add;
    self.OnAddAtkInfo = EH(self.AddAtkInfo,self);
    EM("AtkSelfUnit",self.OnAddAtkInfo);
    self.OnSelfDead = EH(self.SelfDead,self);
    EM("SelfDead",self.OnSelfDead);
end

--是否是攻击者
function My.IsAtker(atkId)
    local atkerInfo = My.atkList[atkId];
    if atkerInfo == nil then
        return false;
    end
    return true;
end

--玩家自己死亡
function My:SelfDead()
    My.ClearCurSltId();
    self:ClearAllAtk();
    My.eSelfDead();
end

--添加攻击者
function My:AddAtkInfo(atkId)
    atkId = tostring(atkId);
    local atkerInfo = My.atkList[atkId];
    if atkerInfo == nil then
        atkerInfo = ObjPool.Get(AttackerInfo);
        My.atkList[atkId] = atkerInfo;
        My.eUpdateAtk(atkId,true);
    end
    atkerInfo:SetAtkInfo(atkId);
end

--删除攻击者
function My:RmAtkInfo(atkId)
    local atkerInfo = My.atkList[atkId];
    if atkerInfo == nil then
        return;
    end
    ObjPool.Add(atkerInfo);
    My.atkList[atkId] = nil;
    My.eUpdateAtk(atkId,false);
end

--清除所有攻击者
function My:ClearAllAtk()
    for k,v in pairs(My.atkList) do
        self:RmAtkInfo(k);
    end
end

--攻击目标改变
function My.SetCurTarget(id)
    id = tostring(id);
    local curId = My.curSelectId;
    --当前选中目标不处理
    if curId == id then
        return;
    end
    My.SetCurSltId(id);
    if curId ~= "0" then
        My.eChgTarget(curId,false);
    end
    if id == "0" then
        return;
    end
    My.eChgTarget(id,true);
end

--是否是当前选中目标
function My.IsSltTarget(id)
    if id == "0" then
        return false;
    end
    if id ~= My.curSelectId then
        return false;
    end
    return true;
end

--设置当前选择Id
function My.SetCurSltId(id)
    My.curSelectId = id;
    local intId = tonumber(id);
    BBMgr:SetCurSltId(id);
end

--检查移除单位是否是当前选中单位
function My:CheckRmUnit(id)
    self:RmAtkInfo(id);
    if My.curSelectId == id then
        self.ClearCurSltId();
    end
end

--清除当前选中的Id
function My.ClearCurSltId()
    My.SetCurTarget("0");
end

--清理
function My:Clear()
    TableTool.ClearDicToPool(My.atkList);
    My.ClearCurSltId();
end

--释放
function My:Dispose()
    self:Clear();
end