RoleSkin = Super:New{Name="RoleSkin"}
Animator = UnityEngine.Animator;
local My = RoleSkin;
My.MountPoint = {"Bip001 AssPosition", "Bip001 Prop1", "Bip001 Spine1", "Bip001 L Foot"}

local GO = UnityEngine.GameObject;
local AssetMgr = Loong.Game.AssetMgr;


function My:Init()
end

function My:Ctor()
    self.isDispose = false
    self.isLoading = false
    self.eLoadModelCB = Event();
    self.count = 0
    self.cacheList = {}
end


function My:CreateFun1(roleRoot,skinList,aniName, needLoadFshFp)
    self.isDispose = false
    self.RoleRoot = roleRoot
    local len = #skinList
    local temp = {}
    for i=1,len do
        table.insert(temp, skinList[i])
    end
    self.SkinList = temp
    self.sex = User.MapData.Sex
    self.AniName = aniName;
    self.needLoadFshFp = needLoadFshFp
    self:SetAdvSkin()
    self:CreateModel(User.MapData.UnitTypeId)
end


function My:CreateFun2(roleRoot,typeId,skinList,sex,aniName)
    self.isDispose = false
    self.RoleRoot = roleRoot;
    self.SkinList = skinList;
    self.sex = sex;
    self.AniName = aniName;
    self:CreateModel(typeId);
end


function My:CreateFun3(roleRoot,aniName)
    self.isDispose = false
    self.RoleRoot = roleRoot;
    self.sex = User.MapData.Sex;
    self.AniName = aniName;
    self:SetOwnerSkL();
    local typeId = User.MapData.UnitTypeId;
    self:CreateModel(typeId);
end

function My:CreateFun4(roleRoot,aniName)
    self.isDispose = false
    self.RoleRoot = roleRoot;
    self.sex = User.MapData.Sex;
    self.AniName = aniName;
    self:SetOwnerNoWing();
    local typeId = User.MapData.UnitTypeId;
    self:CreateModel(typeId);
end

--开始创建 1 roleRoot 角色模型挂载点, 2 typeId 角色类型Id, 3 skinList 皮肤列表, 4 sex 性别, 5 动画名
function My:Create(roleRoot,typeId,skinList,sex,aniName)
    if not self.isLoading then
        self:CreateFun2(roleRoot,typeId,skinList,sex,aniName)
    else
        local cache = {
            id = 2,
            roleRoot = roleRoot,
            typeId = typeId,
            skinList = skinList,
            sex = sex,
            aniName = aniName
        }    
        table.insert(self.cacheList, cache)
    end
end

--创建自己 roleRoot 模型挂载点, aniName 指定播放动画名
function My:CreateSelf(roleRoot,aniName)
    if not self.isLoading then
        self:CreateFun3(roleRoot,aniName)
    else
        local cache = {
            id = 3,
            roleRoot = roleRoot,
            aniName = aniName
        }    
        table.insert(self.cacheList, cache)
    end
end


function My:CreateSelfT(roleRoot,skinList,aniName, needLoadFshFp)
    if not self.isLoading then
        self:CreateFun1(roleRoot,skinList,aniName, needLoadFshFp)
    else
        local cache = {
            id = 1,
            roleRoot = roleRoot,
            skinList = skinList,
            aniName = aniName,
            needLoadFshFp = needLoadFshFp
        }    
        table.insert(self.cacheList, cache)
    end
end


--创建自己 (没有翅膀) roleRoot 模型挂载点, aniName 指定播放动画名
function My:CreateSelfNoWing(roleRoot,aniName)
    if not self.isLoading then
        self:CreateFun4(roleRoot,aniName)
    else
        local cache = {
            id = 4,
            roleRoot = roleRoot,
            aniName = aniName
        }    
        table.insert(self.cacheList, cache)
    end
end

--设置组队界面皮肤列表（没有翅膀）
function My:SetOwnerNoWing()
    self.SkinList={}
    local curList = User.MapData.SkinList;
    local count = curList.Count;
    if count == 0 then
        return;
    end
    local type = nil
    for i = 0,count-1 do
        type = self:GetPandentType(curList[i])
        if type ~= PendantType.Wing then
            self.SkinList[i + 1] = curList[i]
        end
    end
end

--设置自己的皮肤列表
function My:SetOwnerSkL()
    self.SkinList={}
    local curList = User.MapData.SkinList;
    local count = curList.Count;
    if count == 0 then
        return;
    end
    for i = 0,count-1 do
        self.SkinList[i + 1] = curList[i];
    end
end

--获取挂件的类型
function My:GetPandentType(unitTypeId)
    if unitTypeId >= 30200000 and unitTypeId <= 30299999 then
        local type = (unitTypeId / 100000) % 300
        type = math.modf(type)
        return type
    end
    local type = (unitTypeId / 10000) % 300
    type = math.modf(type)
    return type
end

--设置养成皮肤
function My:SetAdvSkin()
    local list = self.SkinList;
    local len = #list;
    local wId = WingMgr.chgID;
    if wId ~= nil and wId ~= 0 then
        len = len + 1;
        self.SkinList[len] = wId;
    end
    local fwp = self:HasFashionWp();
    if fwp == false then
        gwId = GWeaponMgr.chgID;
        if gwId ~= nil and gwId ~= 0 then
            len = len + 1;
            self.SkinList[len] = gwId;
        end
    end
end

--设置模型
function My:CreateModel(typeId)
    local roleAtt = RoleAtt[tostring(typeId)];
    if roleAtt == nil then
        return;
    end
    local modelId = nil;
    local fModelId = self:GetFshMId();
    if fModelId ~= nil then
        modelId = fModelId;
    else
        modelId = roleAtt.modelId;
    end
    local roleBase = RoleBaseTemp[modelId];
    if roleBase == nil then
        return;
    end
    local modelPath = roleBase.uipath;
    if modelPath == nil then
        return;
    end

    self.isLoading = true
    --// LY add begin
    if self.model then
        self:DestroyModel()
    end
    --// LY add end
    AssetMgr.LoadPrefab(modelPath,GbjHandler(self.LoadModelCB,self));
end

--加载模型回调
function My:LoadModelCB(go)
    if self.model then
        self:DestroyModel()
    end
    self.model = go;
    self.modelName = go.name
    if self.isDispose or LuaTool.IsNull(self.RoleRoot) then
        self:DestroyModel()
        return
    end  

    TransTool.AddChild(self.RoleRoot.transform,go.transform);
    LayerTool.Set(go.transform,19);
    self:PlayAni();
    self:SetPartCount()
    self:SetSkins();
    self.eLoadModelCB(go)
end

--播放动画
function My:PlayAni()
    if self.model == nil then
        return;
    end
    if StrTool.IsNullOrEmpty(self.AniName) then
        return;
    end
    local trans = self.model.transform;
    local ani = trans:GetComponentInChildren(typeof(Animator));
    ani:Play(self.AniName);
end

--设置皮肤
function My:SetSkins()
    if self.SkinList == nil then
        self:LoadDfArtf();
        return;
    end
    local len = #self.SkinList;
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        self:SetMountBone(unitTypeId);
    end
    local canCrt = true
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        local _type = My.GetSkinType(unitTypeId);    
        if _type == 4  then
            canCrt = false
        elseif _type == 6 then
            local id = math.floor(unitTypeId/100);
            local info = FashionCfg[tostring(id)];
            if info ~= nil and info.type == 2 then
                canCrt = false
            end
        end 
        self:LoadWeapon(unitTypeId,i);
    end
    if canCrt then
        self:LoadDfArtf();
    end
end

--统计需要加载的部件数量
function My:SetPartCount()
    if self.SkinList == nil then
        self.count = 1
        return;
    end
    local len = #self.SkinList
    local canCrt = true
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        local _type = My.GetSkinType(unitTypeId);    
        if _type == 4 then
            canCrt = false
            self.count = self.count + 1
        elseif  _type == 5 then
            self.count = self.count + 1
        elseif _type == 6 then
            local id = math.floor(unitTypeId/100);
            local info = FashionCfg[tostring(id)];
            if info ~= nil and info.type == 2 then
                canCrt = false
                self.count = self.count + 1
            end          
        elseif _type == 9 and self.needLoadFshFp then
            self.count = self.count + 1
        end
    end
    
    if canCrt then
        self.count = self.count + 1
    end
end

--获取时装模型Id
function My:GetFshMId()
    if self.SkinList == nil then
        return nil;
    end
    local len = #self.SkinList;
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        local type = My.GetSkinType(unitTypeId);
        if type == 6 then -- 时装
            local id = math.floor(unitTypeId/100);
            local info = FashionCfg[tostring(id)];
            if info ~= nil and info.type == 1 then
                local modId = self:GetModelId(info);
                if My.IsExistAs(modId) == false then
                    return nil;
                end
                return modId;
            end
        end            
    end
end

--设置挂点骨骼
function My:SetMountBone(unitTypeId)
    local type = My.GetSkinType(unitTypeId);
    if type == 4 then -- 神兵
        local info = GWeaponMgr:GetBCfg(unitTypeId);
        if info == nil then
            return
        end
        self.ArtfPoint = info.parentPot;
    elseif type == 5 then --翅膀
        local info = WingMgr:GetBCfg(unitTypeId)
        if info == nil then
            return
        end
        self.WBonePoint = info.parentPot;
    elseif type == 6 then
        local id = math.floor(unitTypeId/100);
        local info = FashionCfg[tostring(id)];
        if info ~= nil and info.type == 2 then
            self.FshWpPoint = info.parentPot;
        end
    end
    return;
end

--加载装备
function My:LoadWeapon(unitTypeId,index)
    if index == 0 then
        return;
    end
    local type = My.GetSkinType(unitTypeId);
    if type == 4 then -- 神兵
        -- local canCrt = self:CanCreateWp();
        -- if canCrt == true then
            self:LoadArtf(unitTypeId);
        -- end
    elseif type == 5 then --翅膀
        self:LoadWing(unitTypeId);
    elseif type == 6 then 
        -- local canCrt = self:CanCreateWp();
        -- if canCrt == true then
            self:LoadFshWp(unitTypeId);
        -- end
    elseif type == 9 then
        if self.needLoadFshFp then
            self:LoadFshFp(unitTypeId);
        end
    end 
end

-- --是否可创建武器
-- function My:CanCreateWp(index)
--     if self.FshWpMName ~= nil then
--         return false;
--     end
--     if self.ArtfMName ~= nil then
--         return false;
--     end
--     return true;
-- end

--获取皮肤类型
function My.GetSkinType(unitTypeId)
    if unitTypeId == nil then
        return -1;
    end
    if unitTypeId >= 30200000 and unitTypeId <= 30299999 then
        local type = (unitTypeId / 100000) % 300
        type = math.modf(type)
        return type
    end
    if unitTypeId > 3010000 and unitTypeId <= 3099999 then
        local type = (unitTypeId / 10000) % 300;
        type = math.floor(type);
        return type;
    end
    return -1;
end

--是否有时装武器
function My:HasFashionWp()
    local len = #self.SkinList;
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        local type = My.GetSkinType(unitTypeId);
        if type == 6 then
            local id = math.floor(unitTypeId/100);
            local info = FashionCfg[tostring(id)];
            if info ~= nil and info.type == 2 then
                return true;
            end
        end
    end
    return false;
end
 
--是否有神兵
function My:HasArtf()
    local len = #self.SkinList;
    for i = 1, len do
        local unitTypeId = self.SkinList[i];
        local type = My.GetSkinType(unitTypeId);
        if type == 4 then
            return true;
        end
    end
    return false;
end


--加载默认武器
function My:LoadDfArtf()
    local baseId = tostring(8100);
    local roleBase = RoleBaseTemp[baseId];
    if roleBase == nil then
        return nil;
    end
    local modPath = roleBase.uipath;
    if modPath == nil then
        return;
    end
    self.ArtfPoint = 1;
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadDfArtfCB,self)); 
end


--加载神兵
function My:LoadArtf(unitTypeId)
    local info = GWeaponMgr:GetBCfg(unitTypeId);
    if info == nil then
        return
    end
    local modPath = self:GetModPath(info);
    if modPath == nil then       
        return;
    end
    self.ArtfPoint = 1;
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadArtfCB,self));
end

--加载时装武器
function My:LoadFshWp(unitTypeId)
    local id = math.floor(unitTypeId/100);
    local info = FashionCfg[tostring(id)];
    if info == nil then
        return;
    end
    if info.type ~= 2 then
        return;
    end
    local modPath = self:GetModPath(info);
    if modPath == nil then
        return;
    end
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadFshWpCB,self));
end

--加载时装足迹
function My:LoadFshFp(unitTypeId)
    local id = math.floor(unitTypeId/100);
    local info = FashionCfg[tostring(id)];
    if info == nil then
        return;
    end
    if info.type ~= 5 then
        return;
    end
    local modPath = self:GetModPath(info);
    if modPath == nil then
        return;
    end
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadFshFpCB,self));  
end

--加载翅膀
function My:LoadWing(unitTypeId)
    local modPath = self:GetWingModPath(unitTypeId);
    if modPath == nil then
        local dftWingId = 3050000;
        modPath = self:GetWingModPath(dftWingId);
        if modPath == nil then
            return;
        end
    end
    AssetMgr.LoadPrefab(modPath,GbjHandler(self.LoadWingCB,self));
end

--获取翅膀模型名
function My:GetWingModPath(unitTypeId)
    local info = WingMgr:GetBCfg(unitTypeId)
    if info == nil then
        return nil;
    end
    local modPath = self:GetModPath(info);
    if modPath == nil then
        return nil;
    end
    return modPath;
end

--获取模型路径
function My:GetModPath(info)
    local modelId = self:GetModelId(info);
    if modelId == nil then
        return nil;
    end
    modelId = tostring(modelId);
    if My.IsExistAs(modelId) == false then
        return nil;
    end
    local roleBase = RoleBaseTemp[modelId];
    if roleBase == nil then
        return nil;
    end
    return roleBase.uipath;
end

--获取模型Id
function My:GetModelId(info)
    local modelId = nil;
    if self.sex == 1 then
        modelId = info.mMod;
    elseif self.sex == 0 then
        modelId = info.wMod;
    end
    return modelId;
end

--根据类型Id获取模型Id
function My:GetRoleModelId(typeId)
    local roleAtt = RoleAtt[tostring(typeId)];
    if roleAtt == nil then
        return nil;
    end
    return roleAtt.modelId;
end

--通过资源名加载模型
function My:LoadModel(root,path,rota,pos)
    self.model=root
    self.rota=rota
    self.pos=pos
    AssetMgr.LoadPrefab(path,GbjHandler(self.LoadModelCb,self))
end

--加载模型回调
function My:LoadModelCb(go)
    if LuaTool.IsNull(go) then return end
    TransTool.AddChild(self.model, go.transform)
    -- go.transform.localScale=Vector3.one*345
    -- go.transform.localPosition=self.pos
    -- if self.rota~=Vector3.zero then 
    --     go.transform.localEulerAngles = self.rota
    -- end
    -- local eff = go:GetComponent(typeof(UIEffBinding))
	-- if not eff then eff=go:AddComponent(typeof(UIEffBinding)) end
	-- eff.mNameLayer="ItemModel"
    -- self.uiModel=go
    -- LayerTool.Set(go, 22)

    self.eLoadModelCB(go)
end

--加载默认武器回调
function My:LoadDfArtfCB(go)
    self:IsAllLoad()
    if self.ArtfM then
        self:UnloadDefM()
    end
    self.ArtfM = go;
    self.DftMName = go.name
    if not self.model or self.isDispose then
        self:UnloadDefM()
        return
    end
    self:AddToParent(go,self.ArtfPoint);
end

--加载神兵回调
function My:LoadArtfCB(go)
    self:IsAllLoad()
    if self.ArtfM then
        self:UnloadArtfM()
    end
    self.ArtfM = go;
    self.ArtfMName = go.name;
    if not self.model or self.isDispose then
        self:UnloadArtfM()
        return
    end
    self:AddToParent(go,self.ArtfPoint);
end

--加载时装武器回调
function My:LoadFshWpCB(go)
    self:IsAllLoad()
    if self.FshWpM then
        self:UnloadFshWpM()
    end
    self.FshWpM = go;
    self.FshWpMName = go.name
    if not self.model or self.isDispose then
        self:UnloadFshWpM()
        return
    end
    self:AddToParent(go,self.FshWpPoint);
end

--加载足迹回调
function My:LoadFshFpCB(go)
    self:IsAllLoad()
    if self.FshFpM then
        self:UnloadFshFpM()
    end
    self.FshFpM = go;
    self.FshFpMName = go.name
    if not self.model or self.isDispose then
        self:UnloadFshFpM()
        return
    end
    TransTool.AddChild(self.model.transform, go.transform);
    go.transform.localEulerAngles = Vector3.zero;
    LayerTool.Set(go, self.model.layer);
end

--加载翅膀回调
function My:LoadWingCB(go)
    self:IsAllLoad()
    if self.WingM then
        self:UnloadWingM()
    end
    self.WingM = go;
    self.WingMName = go.name
    if not self.model or self.isDispose then
        self:UnloadWingM()
        return
    end
    self:AddToParent(go,self.WBonePoint);
end

function My:IsAllLoad()
    if self.isDispose then return end
    self.count = self.count - 1
    if self.count == 0 then
        self.isLoading = false
        local cache = table.remove(self.cacheList, 1)
        if cache then
            local id = cache.id
            if id == 1 then
                self:CreateFun1(cache.roleRoot, cache.skinList, cache.aniName, cache.needLoadFshFp)
            elseif id == 2 then
                self:CreateFun2(cache.roleRoot, cache.typeId, cache.skinList, cache.sex, cache.aniName)
            elseif id == 3 then
                self:CreateFun3(cache.roleRoot, cache.aniName)
            elseif id == 4 then
                self:CreateFun4(cache.roleRoot, cache.aniName)
            end
        end  
    end
end

function My:AddToParent(go,mountPoint)
    local TF = TransTool.FindChild;
    local bonePath = My.MountPoint[mountPoint + 1];
    if bonePath == nil then
        return;
    end
    local bone = TransTool.Search(self.model,bonePath,bonePath);
    if bone == nil then
        return;
    end
    TransTool.AddChild(bone.transform,go.transform);
    go.transform.localEulerAngles = Vector3.zero;
    LayerTool.Set(go,bone.gameObject.layer);
end

--资源是否存在
function My.IsExistAs(modelId)
    local roleBase = RoleBaseTemp[modelId];
    if roleBase == nil then
        return false;
    end
    local name = roleBase.uipath;
    local exist = AssetTool.IsExistAss(name);
    return exist;
end

--销毁模型
function My:DestroyModel()
    self:DestroyGbjs();
    self:RlsAsset();
end

--销毁对象
function My:DestroyGbjs()
    self:DestroyGo(self.ArtfM);
    self:DestroyGo(self.WingM);
    self:DestroyGo(self.FshWpM);
    self:DestroyGo(self.FshFpM);
    self:DestroyGo(self.model); 
    self.ArtfM = nil;
    self.WingM = nil;
    self.FshWpM = nil;
    self.model = nil;
    self.FshFpM = nil;
end

--释放资源
function My:RlsAsset()
    self:RlsByName(self.DftMName);
    self:RlsByName(self.ArtfMName);
    self:RlsByName(self.WingMName);
    self:RlsByName(self.FshWpMName);
    self:RlsByName(self.FshFpMName);
    self:RlsByName(self.modelName);
    self.DftMName = nil;
    self.ArtfMName = nil;
    self.WingMName = nil;
    self.FshWpMName = nil;
    self.modelName = nil;
    self.FshFpMName = nil
end

function My:UnloadDefM()
    self:DestroyGo(self.ArtfM);
    self:RlsByName(self.DftMName);
    self.ArtfM = nil
    self.DftMName = nil
end

function My:UnloadArtfM()
    self:DestroyGo(self.ArtfM);
    self:RlsByName(self.ArtfMName);
    self.ArtfM = nil
    self.ArtfMName = nil
end

function My:UnloadWingM()
    self:DestroyGo(self.WingM);
    self:RlsByName(self.WingMName);
    self.WingM = nil
    self.WingMName = nil
end

function My:UnloadFshWpM()
    self:DestroyGo(self.FshWpM);
    self:RlsByName(self.FshWpMName);
    self.FshWpM = nil
    self.FshWpMName = nil
end

function My:UnloadFshFpM()
    self:DestroyGo(self.FshFpM);
    self:RlsByName(self.FshFpMName);
    self.FshFpM = nil
    self.FshFpMName = nil
end


--销毁对象
function My:DestroyGo(gbj)
    if LuaTool.IsNull(gbj) == false and LuaTool.IsNull(gbj.gameObject)==false then
        GO.Destroy(gbj.gameObject);
    end
end

--释放
function My:RlsByName(name)
    if name ~= nil then
        AssetMgr.Instance:Unload(name, ".prefab", false);
    end
end

function My:Clear()
    self:DestroyModel();
    self.needLoadFshFp = false
    self.isLoading = false
    self.count = 0
    TableTool.ClearDic(self.cacheList)
    TableTool.ClearUserData(self);
end

function My:DestroyUIModel()
    Destroy(self.uiModel)
end

function My:Dispose()
    self.isDispose = true;
    self:Clear();
end

return My;