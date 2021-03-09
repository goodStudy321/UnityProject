SpiriteModItem = Super:New{Name = "SpiriteModItem"}

local My = SpiriteModItem

function My:Init()

end

--激活
function My:SetActive(at,modId,modRoot)
    if (self.mod == nil) and (at == true) then
      self:LoadMod(modId,modRoot)
    elseif (self.mod==nil) then
        self:LoadMod(modId,modRoot)
    else
      self.mod:SetActive(at)
      self.mod.transform.localEulerAngles = Vector3.New(0,180,0)
    end
end

function My:LoadMod(modId,modRoot)
    local name = self:GetModName(modId)
    if name == nil then return end
    self.modRoot = modRoot
    local tran = self.modRoot:Find(name)
    if tran then
        self:SetEuler(tran)
        self.mod = tran.gameObject
        self.mod.transform.localEulerAngles = Vector3.New(0,180,0)
        self.mod:SetActive(true)
    else
        local GH = GbjHandler(self.LoadModCb,self)
        Loong.Game.AssetMgr.LoadPrefab(name, GH)
    end
end

--加载模型回调
function My:LoadModCb(go)
    local modRoot = self.modRoot
    if LuaTool.IsNull(modRoot) then
        Destroy(go)
    else
        self.mod = go
        go:SetActive(true)
        local tran = go.transform
        tran.parent = modRoot
        self:SetEuler(tran)
        tran.localPosition = Vector3.zero
        tran.localEulerAngles = Vector3.New(0,180,0)
    end
end

--通过配置id获取模型名称
function My:GetModName(id)
    local modId = tostring(id)
    local modCfg = RoleBaseTemp[modId]
    local name = modCfg and modCfg.path
    return name
end

function My:SetEuler(tran)
    -- self.rotTran = tran:GetChild(0)
    -- self.localEuler = Vector3.New(0,180,0)
end

function My:Dispose()
    self.mod = nil
    TableTool.ClearUserData(self)
end

return My