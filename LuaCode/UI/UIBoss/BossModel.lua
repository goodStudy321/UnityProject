BossModel = { Name="BossModel" }
local My = BossModel;
local GO = UnityEngine.GameObject;
local AssetMgr = Loong.Game.AssetMgr;

--显示模型
function My:ShowModel(parent,monsId,uiPos,uiElAgl,what)
    self.parent = parent;
    local bossId = tostring(monsId);
    local modPath=nil;
if what==1 then
    local info = BinTool.Find(CollectionTemp,tonumber(monsId));
    if info == nil then
        return;
    end
    modPath= info.mod;
else 
    local info = MonsterTemp[bossId];
    if info == nil then
        return;
    end
    local modId = tostring(info.modId);
    info = RoleBaseTemp[modId];
    if info == nil then
        return;
    end

     modPath = info.uipath;
    if modPath == nil then
        modPath = info.path;
    end
end
    self.pos = uiPos;
    self.elAgl = uiElAgl;
    self.modPath=modPath;
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadDone,self));
end

--加载完成
function My:LoadDone(go)
    if go == nil then
        return;
    end
    if self.parent == nil then
        GO.Destroy(go);
        return;
    end
    self.model = go;
    TransTool.AddChild(self.parent,go.transform);
    go.transform.localEulerAngles = Vector3.New(0,0,0);
    self:SetAngle();
    self:SetPos();
    LayerTool.Set(go,19);
end

--设置角度
function My:SetAngle()
    if self.parent == nil then
        return;
    end
    if self.elAgl == nil then
        return;
    end
    local len = #self.elAgl;
    if len ~= 3 then
        return;
    end
    self.parent.localEulerAngles = Vector3.New(self.elAgl[1],self.elAgl[2],self.elAgl[3]);
end

--设置位置
function My:SetPos()
    if self.parent == nil then
        return;
    end
    if self.pos == nil then
        return;
    end
    local len = #self.pos;
    if len ~= 3 then
        return;
    end
    self.parent.localPosition = Vector3.New(self.pos[1],self.pos[2],self.pos[3]);
end

--销毁模型
function My:DestroyModel()
    if self.parent == nil then
        return;
    end
    if self.model == nil then
        return;
    end
    
    DestroyImmediate(self.model);
    self.model = nil;

    if self.modPath~=nil then
        AssetMgr.Instance:Unload(self.modPath,".prefab",false);
        self.modPath=nil
    end
    self.parent = nil;
    self.Pos = nil;
    self.elAgl = nil;
end