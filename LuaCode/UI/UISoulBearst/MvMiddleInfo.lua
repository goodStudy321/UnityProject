MvMiddleInfo = Super:New{Name = "MvMiddleInfo"}

local M = MvMiddleInfo

local len = 5

function M:Ctor()
    self.cellList = {}
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.go = go

    self.icon = G(UITexture, trans, "Icon")

    self.fx1 = FC(trans, "Icon/FX_shensou_bao_UI")
    self.fx2 = FC(trans, "Icon/FX_shensou_UI")

    local parent = F(trans, "EquipList")
    for i=1,len do
        local go = FC(parent, tostring(i))
        local cell = ObjPool.Get(MvSBCell)
        cell:Init(go)
        table.insert(self.cellList, cell)
    end

    self.btnTakeOff = FC(trans, "BtnTakeOff")
    S(self.btnTakeOff, self.OnTakeOff, self)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateCell()
    self:UpdateIcon()
    self:UpdateBtnState()
    self:UpdateIconState()
    self:UpdateFX()
end

function M:UpdateFX()
    if self.data.state ~= 2 then
        self.fx1:SetActive(false)
        self.fx2:SetActive(false)
    elseif not self.fx2.activeSelf then 
        self.fx2:SetActive(true)
    end
end

function M:UpdateBtnState()
    local condList = self.data.condList
    local state = false
    for i=1,#condList do
        if condList[i].isUse then
            state = true
            break
        end
    end
    if state then
        UITool.SetNormal(self.btnTakeOff)
    else
        UITool.SetGray(self.btnTakeOff)
    end   
end

function M:UpdateFX1()
    if self.data.state == 2 then
        self.fx1:SetActive(true)
        self:DalayDeactive()
    else
        self.fx1:SetActive(false)
        self.fx2:SetActive(false)
    end
end

function M:DalayDeactive()
    if not self.timer then
        self.timer = ObjPool.Get(iTimer)   
        self.timer.invlCb:Add(self.InvlCb, self)
        self.timer.complete:Add(self.CompleteCb, self)
    end
    self.timer:Stop()
    self.timer:Start(1, 0.1)
end

function M:InvlCb()
    if self.timer.cnt > 0.1 then
        self.fx2:SetActive(true)
    end
end

function M:CompleteCb()
    self.fx1:SetActive(false)
end

function M:UpdateIconState()
    if self.data.state == 2 then
        UITool.SetNormal(self.icon)
    else
        UITool.SetGray(self.icon)
    end
end

function M:UpdateCell()
    local data = self.data.condList
    local list = self.cellList
    for i=1, #list do
        list[i]:UpdateData(data[i])
    end
end

function M:UpdateCellsRedPoint()
    local list = self.cellList
    for i=1, #list do
        list[i]:UpdateRedPoint()
    end
end

function M:TakeOff()
    local list = self.cellList
    for i=1,#list do
        list[i]:SetActive(false)
    end
end


function M:UpdateIcon()
    AssetMgr:Load(self.data.texture, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:OnTakeOff()
    SoulBearstMgr:ReqMythicalEquipUnload(self.data.id , 0)
end

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end   
end

return M