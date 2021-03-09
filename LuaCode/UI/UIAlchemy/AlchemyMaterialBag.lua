AlchemyMaterialBag = Super:New{Name = "AlchemyMaterialBag"}

require("UI/UIAlchemy/AlchemyMaterialBagCell")

local M = AlchemyMaterialBag

M.mCells = {}
M.mSelectList = {}

M.mTotal = 0

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    self.mGo = go
    self.mGrid = G(UIGrid, trans, "Container/ScrollView/Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mPrefab:SetActive(false)

    self.mMaterialTime = G(UILabel, trans, "MaterialTime")
    self.mAlchemyTime = G(UILabel, trans, "AlchemyTime")

    self.mBtnChoose = FC(trans, "BtnChoose")
    self.mBtnSubmit = FC(trans, "BtnSubmit")
    self.mBtnClose = FC(trans, "BtnClose")
    
    S(self.mBtnChoose, self.OnChoose, self)
    S(self.mBtnSubmit, self.OnSubmit, self)
    S(self.mBtnClose, self.Close, self)
end

function M:OnChoose()
    local list = self.mCells
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() and cell:NotSelect() then
            cell:UpdateSelect(true)
            self:SelectItem(true, i)
        end
    end
    self:UpdateTatolProgress()
end

function M:OnSubmit()
    local list = self.mSelectList
    local cells = self.mCells
    local temp = {}
    for i=1,#list do
        local cell = cells[list[i]]
        local data = cell.Data
        local id = data.ID
        local num = data.Num
        for j=1,num do
            table.insert(temp, id)
        end
    end
    if #temp == 0 then
        UITip.Log("请选中材料后提交")
    else
        AlchemyMgr:ReqRoleBgAlchemySubmit(temp)
        self:Close()
        UITip.Log("提交成功")
    end
end

function M:UpdateMaterialTime()
    local curProgress = AlchemyMgr:GetCommonAlchemyCurProgress()
    self.mMaterialTime.text = string.format("材料进度:%s/%s", curProgress + self.mTotal, AlchemyMgr.OnceNeed)
end

function M:UpdateAlchemyTime()
    local remainTime = AlchemyMgr:GetCommonAlchemyRemainTime()
    local curProgress = AlchemyMgr:GetCommonAlchemyCurProgress()
    local addTime = math.floor((self.mTotal+curProgress)/AlchemyMgr.OnceNeed)
    self.mAlchemyTime.text = string.format("[99886BFF]凡品炼丹次数:%s[00FF00FF]+%s", remainTime, addTime)
end


function M:UpdateCells()
    local data = AlchemyMgr:GetMaterialBagData()
    if not data then return end
    local len = #data
    local list = self.mCells
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.mPrefab)
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local item = ObjPool.Get(AlchemyMaterialBagCell)
            item:Init(go, i)
            item.eClick:Add(self.OnSelectItem, self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
end

function M:UpdateData()
    self:ClearSelectList()
    self:UpdateCells()
    self:UpdateMaterialTime()
    self:UpdateAlchemyTime()
end

function M:OnSelectItem(isSelect, index)
    self:SelectItem(isSelect, index)
    self:UpdateTatolProgress()
end

function M:SelectItem(isSelect, index)
    if isSelect then
        TableTool.Add(self.mSelectList, index)
    else
        TableTool.Remove(self.mSelectList, index)
    end
end

function M:UpdateTatolProgress()
    local list = self.mSelectList
    local cells = self.mCells
    local total = 0
    for i=1,#list do
        local cell = cells[list[i]]
        local data = cell.Data
        total = total + data.Num * data.Cost
    end
    self.mTotal = total
    self:UpdateMaterialTime()
    self:UpdateAlchemyTime()
end

function M:Open()
    self:SetActive(true) 
    self:UpdateData()
end

function M:Close()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:ClearSelectList()
    self.mTotal = 0
    TableTool.ClearDic(self.mSelectList)
end

function M:Dispose()
    self:ClearSelectList()
    TableTool.ClearDicToPool(self.mCells)
    TableTool.ClearUserData(self)
end

return M