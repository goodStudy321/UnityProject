--[[
    进阶
]]

UIShowGetCPM = UIBase:New{Name = "UIShowGetCPM"}
local My = UIShowGetCPM
local AssetMgr = Loong.Game.AssetMgr

My.tab = 0

function My:InitCustom()
    local root = self.root
    local TF = TransTool.FindChild
    local name = self.Name

    self.togList = {}
    for i=1,6 do
        self.togList[i] = TF(root, "Roots").transform:GetChild(i).gameObject
    end
    self.effect = TF(root, "Roots/ui_kaiqi", name).gameObject
    UITool.SetBtnClick(root, "CloseBtn", name, self.CloseBtn, self)
end

function My.OpenCPM(ID, tab)
    My.tab = tab
    AdvMgr.eGetCPM(false)
    UIShowGetCPM.id = tostring(ID)
    UIMgr.Open(UIShowGetCPM.Name)
    -- UIAdv.modRoot.gameObject:SetActive(false)
end

function My:UpModel(id)
    local modelBase = RoleBaseTemp[tostring(id)]
    local type = modelBase.type
    if type == 8 then
        self.tog = self.togList[1]
    elseif type == 9 then
        self.tog = self.togList[4]
    elseif type == 10 then
        self.tog = self.togList[3]
    elseif type == 11 then
        self.tog = self.togList[2]
    elseif type == 12 then
        self.tog = self.togList[5]
    elseif type == 14  then
        self.spModel = 1
        self.tog = self.togList[6]
    end
    if modelBase == nil then  return  end
    local modelPath = modelBase.path
    if modelPath == nil then  return  end
    AssetMgr.LoadPrefab(modelPath, GbjHandler(self.LoadModel, self))
end

function My:LoadModel(go)
    if self.tog == nil then
        return
    end
    if self.spModel ~= nil then
        go.transform.localEulerAngles = Vector3.New(0,180,0)
    end
    self.tog:SetActive(true)
    self.effect:SetActive(true)
    TransTool.AddChild(self.tog.transform, go.transform)
    LayerTool.Set(go.transform, 19)
end

function My:OpenCustom()
    self:UpModel(self.id)
end

function My:CloseBtn()
    if self.spModel and My.tab ~= 4 then
        RobberyMgr.eOpenSpUI()
    end
    AdvMgr.eGetCPM(true)
    self:Close()
end

function My:CloseCustom()

end

function My:Clear()
    -- if UIAdv.modRoot then
    --     UIAdv.modRoot.gameObject:SetActive(true)
    -- end
    My.tab = 0
    TableTool.ClearDic(self.togList)
    self.togList = nil
    self.id = nil
    self.tog = nil
    self.spModel = nil
end

function My:DisposeCustom()
    self:Clear()
end

return My
