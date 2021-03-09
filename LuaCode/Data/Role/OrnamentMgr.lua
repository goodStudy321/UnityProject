require("Data/Role/OnmInfo")
OrnamentMgr = {Name = "OrnamentMgr"}
local My = OrnamentMgr;
local AssetMgr = Loong.Game.AssetMgr;

My.BonePoint = {}
My.BonePoint[1] = "Bip001 Head";
My.BonePoint[2] = "Bip001 L Foot";
My.BonePoint[3] = "Bip001 R Foot";

--配饰表
My.Ornaments = {}

function My:Init()
    self:AddLsnr();
end

--添加监听
function My:AddLsnr()
    EventMgr.Add("AddOrnament",EventHandler(self.AddOrnament,self));
    EventMgr.Add("RemoveOrnament",EventHandler(self.RemoveOrnament,self));
end

--添加配饰
function My:AddOrnament(uid, trans, onmId)
    if trans == nil then
        return;
    end
    local id = tostring(onmId);
    local info = OrnamentInfo[id];
    if info == nil then
        return;
    end
    local parent = My.GetBoneTrans(trans,info.parentPot);
    if parent == nil then
        return;
    end
    local path = My.GetModName(info.modID);
    if path == nil then
        return;
    end
    local exist = AssetTool.IsExistAss(path);
    if exist == false then
        return;
    end
    local has, onmIf = self:AddOnm(uid,onmId,parent)
    if has == false then
        return;
    end
    local del = ObjPool.Get(DelGbj);
	del:Add(onmIf);
	del:SetFunc(onmIf.LoadDone,onmIf);
    AssetMgr.LoadPrefab(path,GbjHandler(del.Execute,del));
end

--移除配饰
function My:RemoveOrnament(uid, trans, onmId)
    self:ClearOnmIf(uid,onmId);
    if trans == nil then
        return;
    end
    local id = tostring(onmId);
    local info = OrnamentInfo[id];
    if info == nil then
        return;
    end
    local path = My.GetModName(info.modID);
    local child = TransTool.Search(trans, path,trans.name);
    if child == nil then
        return;
    end
    GameObject.Destroy(child.gameObject);
end

--获取骨骼变换
function My.GetBoneTrans(trans,parentPot)
    if parentPot == nil then
        return nil;
    end
    local prtPStr = My.BonePoint[parentPot];
    if prtPStr == nil then
        return nil;
    end
    local parent = TransTool.Search(trans, prtPStr,trans.name);
    if parent == nil then
        return nil;
    end
    return parent;
end

--获取模型名
function My.GetModName(modId)
    modId = tostring(modId);
    local modInfo = RoleBaseTemp[modId];
    if modInfo == nil then
        return;
    end
    return modInfo.path;
end

--添加配置
function My:AddOnm(uid,onmId,parent)
    local idStr = tostring(uid); 
    local list = My.Ornaments[idStr];
    local onmIf = nil;
    if list == nil then
        list = {};
        onmIf = self:SetList(list,onmId,uid,parent);
        My.Ornaments[idStr] = list;
    else
        onmIf = list[onmId];
        if onmIf ~= nil then
            return false;
        end
        onmIf = self:SetList(list,onmId,uid,parent);
    end
    return true,onmIf;
end

--设置列表
function My:SetList(list,onmId,uid,parent)
    local onmIf = ObjPool.Get(OnmInfo);
    onmIf:SetInfo(uid,parent);
    list[onmId] = onmIf;
    return onmIf;
end

--移除配置
function My:ClearOnmIf(uid,onmId)
    local idStr = tostring(uid);
    local list = My.Ornaments[idStr];
    if list == nil then
        return;
    end
    if onmId == -1 then --onmId==-1时,说明是单位销毁操作
        self:ClearUnitOnm(idStr,list);
        return;
    end
    local onmIf = list[onmId];
    if onmIf == nil then
        return;
    end
    ObjPool.Add(onmIf);
    list[onmId] = nil;
end

--单位配饰从配饰列表中移除
function My:ClearUnitOnm(uid,list)
    for k,v in pairs(list) do
        ObjPool.Add(v);
        list[k] = nil;
    end
    My.Ornaments[uid] = nil;
end

--清理
function My:Clear()
    for k,v in pairs(My.Ornaments) do
        self:ClearUnitOnm(k,v);
    end
end

--释放
function My:Dispose()
    self:Clear();
end

return My;