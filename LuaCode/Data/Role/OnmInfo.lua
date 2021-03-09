OnmInfo = Super:New{Name = "OnmInfo"}
local My = OnmInfo;

--设置信息
function My:SetInfo(uid,parent)
    self.uid = uid;
    self.trans = parent;
end

--加载完成回调
function My:LoadDone(go)
    if go == nil then
        return;
    end
    if self.uid == nil then
        GameObject.Destroy(go);
        return;
    end
    self.onmGo = go;
    local c = go.transform;
    TransTool.AddChild(self.trans,c);
    c.localEulerAngles = Vector3.zero;
    local uid = User.instance.MapData.UID;
    if self.uid == uid then
        AssetMgr:SetPersist(go.name,".prefab",true);
    end
end

--销毁对象
function My:Destroy()
    if LuaTool.IsNull(self.onmGo) then
        return;
    end
    local go = self.onmGo;
    GameObject.Destroy(go);
end

--释放
function My:Dispose()
    self:Destroy();
    self.uid = nil;
    self.trans = nil;
end