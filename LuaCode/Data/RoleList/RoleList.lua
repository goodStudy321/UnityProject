require("Data/RoleList/RoleListInfo")
require("Data/RoleList/AtkInfoMgr")
require("Data/RoleList/WBRcvHp")
require("Data/RoleList/WBChgOwner")
RoleList = {Name = "RoleList"}
local My = RoleList;
My.eCreate = Event();
My.eRemove = Event();
My.eSetBelonger = Event();
My.eRcvBelonger = Event();
My.eSelfChgTmOrFml = Event();
My.eChgHp = Event();
My.colors = {Color.New(205,67,67,255)/255, Color.New(67,205,77,255)/255, Color.New(200,208,227,255)/255};

--显示列表
My.List = {}
--boss归属者
My.bossBelonger = nil;

function My:Init()
    AtkInfoMgr:Init();
    WBRcvHp:Init();
    WBChgOwner:Init();
    self:AddLsnr();
end

--创建其他单位
function My:UpdateUnit(unit, level, sex, add)
    local id = tostring(unit.UnitUID);
    local typeId = unit.TypeId;
    local name = unit.Name;
    local teamId = unit.TeamId;
    local familyId = tostring(unit.FamilyId);
    local hp = RoleAssets.LongToNum(unit.HP);
    local maxHp = RoleAssets.LongToNum(unit.MaxHP);
    if add == true then
        self:Add(id,typeId,level,name,teamId,familyId,sex,hp,maxHp);
    else
        self:Remove(id);
        AtkInfoMgr:CheckRmUnit(id);
    end
end

--添加单位
function My:Add(id,typeId,level,name,teamId,familyId,sex,hp,maxHp)
    if self.List[id] ~= nil then
        return;
    end
    local info = ObjPool.Get(RoleListInfo);
    info:SetInfo(id,typeId,level,name,teamId,familyId,sex,hp,maxHp);
    self.List[id] = info;
    My.eCreate(info);
end

--移除单位
function My:Remove(id)
    local info = self.List[id];
    if info == nil then
        return;
    end
    ObjPool.Add(info);
    self.List[id] = nil;
    My.eRemove(id);
end

--设置归属者
function My:SetBelonger(id,level,name,teamId,familyId)
    id = tostring(id);
    familyId = tostring(familyId);
    local info = My.bossBelonger;
    if info == nil then
        info = ObjPool.Get(RoleListInfo);
        My.bossBelonger = info;
    else
        My.eRcvBelonger();
    end
    info:SetInfo(id,typeId,level,name,teamId,familyId);
    My.eSetBelonger();
end

--队伍或仙盟Id改变
function My:ChgTmOrFml(id,teamId,familyId)
    id = tostring(id);
    familyId = tostring(familyId);
    if id == User.MapData.UIDStr then
        My.UpdateInfo();
        My.eSelfChgTmOrFml();
        return;
    end
    local info = My.List[id];
    if info == nil then
        return;
    end
    local oldTmFml = info.isTeamOrFml;
    info:SetTmFml(teamId,familyId);
    local belonger = My.IsBelonger(id);
    if belonger == true then
        local bBlg = My.bossBelonger;
        oldTmFml = bBlg.isTeamOrFml;
        bBlg:SetTmFml(teamId,familyId);
        if bBlg.isTeamOrFml == oldTmFml then
            return;
        end
        My.eSetBelonger();
    else
        if oldTmFml == info.isTeamOrFml then
            return;
        end
        My.eCreate(info);
    end
end

--更新信息
function My.UpdateInfo()
    for k,v in pairs(My.List) do
        v:RfTmFml();
    end
    local blg = My.bossBelonger;
    if blg ~= nil then
        blg:RfTmFml();
    end
end

--是否是归属者
function My.IsBelonger(id)
    local bblg = My.bossBelonger;
    if bblg == nil then
        return false;
    end
    if id ~= bblg.id then
        return false;
    end
    return true;
end

--是否存在归属者
function My.ExistBlg()
    local bblg = My.bossBelonger;
    if bblg == nil then
        return false;
    end
    if bblg.id == "0" then
        return false;
    end
    return true;
end

--是否队友或盟友
function My.TeamOfFml(id,teamId,familyId)
    if id == User.MapData.UIDStr then
        return true;
    end
    local selfTmID = User.MapData.TeamID;
    local selfFmlID = User.MapData.FamilyID;
    selfFmlID = tostring(selfFmlID);
    if selfTmID ~= 0 and teamId == selfTmID then
        return true;
    end
    if selfFmlID ~= "0" and familyId == selfFmlID then
        return true;
    end
    return false;
end

--血量改变
function My:ChgHp(id,hp,maxHp)
    id = tostring(id);
    local ownerId = User.MapData.UIDStr;
    local blg = RoleList.IsBelonger(ownerId);
    local info = nil;
    if blg == true then
        info = My.bossBelonger;
    else
        info = self.List[id];
    end
    if info == nil then
        return;
    end
    hp = RoleAssets.LongToNum(hp);
    maxHp = RoleAssets.LongToNum(maxHp);
    info:RfHp(hp,maxHp);
    My.eChgHp(id);
end

--是否是怪物
function My.IsMons(info)
    if info == nil then
        return false;
    end
    local typeId = info.typeId;
    local result = My.IsMonster(typeId);
    if result == true then
        return true;
    end
end

--是否怪物
function My.IsMonster(typeId)
    local monster = false;
    local type = UnitType.GetUnitType(typeId);
    if type == UnitType.Monster or type == UnitType.Boss then
        monster = true;
    end
    return monster;
end

--添加监听
function My:AddLsnr()
    local EH = EventHandler;
    local EM = EventMgr.Add;
    self.OnUpdateUnit = EH(self.UpdateUnit,self);
    EM("OnUpdateUnit",self.OnUpdateUnit);
    self.OnBelonger = EH(self.SetBelonger,self);
    EM("BossBelonger",self.OnBelonger);
    self.OnChgTmOrFml = EH(self.ChgTmOrFml,self);
    EM("ChgTmOrFml",self.OnChgTmOrFml);
    self.OnChgHp = EH(self.ChgHp,self);
    EM("OnChangeUnitHP",self.OnChgHp);
end

function My:Clear()
    My.bossBelonger = nil;
    for k,v in pairs(self.List) do
        self:Remove(k);
    end
    AtkInfoMgr:Clear();
end

function My:Dispose()
    self:Clear();
end

return My;