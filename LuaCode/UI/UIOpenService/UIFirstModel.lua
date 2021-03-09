
UIFirstModel = Super:New{Name = "UIFirstModel"}
local My = UIFirstModel
-- local AssetMgr = Loong.Game.AssetMgr

function My:Init(go)
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local des = self.Name

    self.WeaMod = TF(trans, "WeaponModel").transform
    self.CloMod = TF(trans, "ClothesModel").transform
end

function My:Update(weaMod, cloMod)
    self:CleanData()
    local weaPath = self:ReturnPath(weaMod)
    local cloPath = self:ReturnPath(cloMod)
    LoadPrefab(weaPath, GbjHandler(self.LoadWeaModCb, self))
    LoadPrefab(cloPath, GbjHandler(self.LoadcloModCb, self))    
end

function My:ReturnPath(ID)
    id = tostring(ID)
    local modBase = RoleBaseTemp[id]
    if modBase == nil then return nil end
    local modPath = modBase.uipath
    if modPath ==nil then
        modPath = modBase.path        
        if modPath == nil then return end
    end
    return modPath
end

function My:LoadWeaModCb(go)
    self.modelName1 = go
    go.transform.parent = self.WeaMod
    self:SetPos(go)    
end

function My:LoadcloModCb(go)
    self.modelName = go
    go.transform.parent = self.CloMod
    self:SetPos(go)
end

function My:SetPos(go)
    go.transform.localScale=Vector3.one
	go.transform.localRotation=Quaternion.New(0,0,0,0)
	go.transform.localPosition=Vector3.zero
    go.layer = 19
    LayerTool.Set(go, 19)
end

function My:CleanData()
    if LuaTool.IsNull(self.modelName) then return end
    if LuaTool.IsNull(self.modelName1) then return end

    if self.modelName then
        AssetMgr:Unload(self.modelName.name,".prefab",false)
        GameObject.DestroyImmediate(self.modelName)
        self.modelName = nil
    end
    if self.modelName1 then
        AssetMgr:Unload(self.modelName1.name,".prefab",false)
        GameObject.DestroyImmediate(self.modelName1)
        self.modelName1 = nil
    end
end

function My:Dispose()
    self:CleanData()
end

return My