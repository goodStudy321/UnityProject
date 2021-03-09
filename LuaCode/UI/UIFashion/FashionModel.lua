FashionModel = Super:New{Name = "FashionModel"}

local M = FashionModel

function M:Ctor()
    self.texList = {}
end

function M:Init(root)
    local FC = TransTool.FindChild 
    local F = TransTool.Find
    local G = ComTool.Get

    self.root = F(root, "ModelRoot")
    self.bg = FC(root, "Bg")
    self.icon = G(UITexture, self.bg.transform, "Icon")

    FashionMgr:ResetSkinList()
    self.model = ObjPool.Get(RoleSkin)
    self.model.eLoadModelCB:Add(self.SetModel, self)
    -- self.model:CreateSelf(self.root)
    self:CreateModel()
end

function M:CreateModel()   
    self.root.gameObject:SetActive(true)
    local data =  FashionMgr:GetSkinList()
    self.model:CreateSelfT(self.root, data, nil, true)
end

function M:SetModel(go)
    if LuaTool.IsNull(go) then return end
    go.transform.localScale = Vector3(360,360,360)
    go.transform.localPosition = Vector3(-50,-275,-36)
    go.transform.localRotation = Quaternion.Euler(0,160,0)
end

function M:UpdateModel(_type, baseId)
    self.bg:SetActive(false)
    self.root.gameObject:SetActive(false)
    self.model:DestroyModel()
    if _type ~= 3 and _type ~= 4 then
       self:CreateModel()
    else
        self:CreateUI(baseId, _type)
    end
end

function M:CreateUI(baseId, _type)
    self._type = _type
    self.bg:SetActive(true)
    local temp = FashionCfg[tostring(baseId)]
    if not temp then return end
    local icon = User.MapData.Sex==1 and temp.mIcon or temp.wIcon
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.bg then
        self.icon.mainTexture = tex
        if self._type == 3 then
            self.icon.type = UIBasicSprite.Type.Sliced
            self.icon:SetDimensions(256, 100) 
        else
           self.icon.type = UIBasicSprite.Type.Simple
            self.icon:SetDimensions(256, 256) 
        end
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:SetSuitModel(data)
    self.bg:SetActive(false)
    self.root.gameObject:SetActive(true)
    self.model:DestroyModel()
    local list = {}
    for i=1,#data do
        table.insert(list, data[i].curId)
    end
    self.model:CreateSelfT(self.root, list, nil, true)
end

function M:Dispose()
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
    self.model.eLoadModelCB:Remove(self.SetModel, self)
    ObjPool.Add(self.model)
    self.model = nil
    self._type = nil
end

return M