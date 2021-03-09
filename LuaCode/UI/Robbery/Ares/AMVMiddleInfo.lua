AMVMiddleInfo = Super:New{Name = "AMVMiddleInfo"}

require("UI/Robbery/Ares/AMVMiddleCell")
require("Tool/MyGbjPool")

local M = AMVMiddleInfo

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local G = ComTool.Get

    local parent = F(trans, "Container")
    for i=1,4 do
        local go = FC(parent, "Cell"..i)
        local cell = ObjPool.Get(AMVMiddleCell)
        cell:Init(go)
        table.insert(self.cellList, cell)
    end

    self.lock = FC(parent, "Lock")
    self.fx = FC(parent, "UI_feng")
    self.modelRoot = F(trans, "ModelRoot")
    self.suitName = G(UILabel, trans, "Name")
    self.suitLv = G(UILabel, self.suitName.transform, "Lv")
    self.fight = G(UILabel, trans, "Fight")
    self.gbjPool = ObjPool.Get(MyGbjPool)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AMVMiddleCell.eClick[key](AMVMiddleCell.eClick, self.OnClickCell, self)
end

function M:OnClickCell(data)
    AresMgr.eClickEquip(data)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateCell()
    self:UpdateModel()
    self:UpdateLockFX()
    self:UpdateCurLevel()
    self:UpdateFight()
end

function M:UpdateCell()
    local data = self.data.equipList
    local list = self.cellList
    for i=1,#list do
        list[i]:UpdateData(data[i])
    end
end

function M:UpdateModel()
    if self.curModel and self.curModel.name == self.data.modelPath then return end
    local go = self.gbjPool:Get(self.data.modelPath)
    if go then
        self:LoadModelCb(go)
    else
        Loong.Game.AssetMgr.LoadPrefab(self.data.modelPath, GbjHandler(self.LoadModelCb,self))
    end
end

function M:LoadModelCb(go)
    if not LuaTool.IsNull(self.modelRoot) then
        self.gbjPool:Add(self.curModel)
        self.curModel = go
        go.transform:SetParent(self.modelRoot)
        go.transform.localPosition = Vector3(0,0,0)
        go.transform.localScale = Vector3(375, 375, 375)
        go.transform.localRotation = Quaternion.Euler(0,180,0)
    else
        self:Unload(go)
    end
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end

function M:UpdateLockFX()
    self.lock:SetActive(not self.data.state)
    self.fx:SetActive(not self.data.state)
end

function M:UpdateCurLevel()
    self.suitLv.text = self.data.state and string.format("开光%s阶", self.data.level) or  "未获得" 
    self.suitName.text = string.format("[F4DDBDFF]%s", self.data.name)
end

function M:UpdateFight()
    self.fight.text = self.data.fight
end

function M:Dispose()
    self:SetLsnr("Remove")
    self.data = nil
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
    ObjPool.Add(self.gbjPool)
    self.gbjPool = nil
    self:Unload(self.curModel)
    self.curModel = nil
end

return M