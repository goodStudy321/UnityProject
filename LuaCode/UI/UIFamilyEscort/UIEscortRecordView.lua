UIEscortRecordView = Super:New{Name = "UIEscortRecordView"}

local M = UIEscortRecordView

M.mCellList = {}

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    
    self.mGo = go
    self.mSlider = G(UISlider, trans, "Slider")
    self.mScrollView = G(UIScrollView, trans, "ScrollView")
    self.mTable = G(UITable, trans, "ScrollView/Table")
    self.mPrefab = FC(trans, "ScrollView/Table/Cell")
    self.mPrefab:SetActive(false)
end

function M:Open()
    self:SetActive(true)
    self:UpdateData()
end

function M:UpdateData()
    local data = FamilyEscortMgr:GetEscortLogs()
    local len = #data
    local list = self.mCellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i].text = self:SetText(data[i])
            list[i].gameObject:SetActive(true)      
        elseif i <= count then
            list[i].gameObject:SetActive(false)
        else
            self:CreateLog(data[i])
        end
    end
    self:UpdateScrollbars()
end

function M:SetText(data)
    local id = data.Id
    local list = data.Texts
    local text = EscortLogCfg[id].log
    for i=1,#list do
        text=string.gsub(text,"#",list[i],1)
    end
    return text
end

function M:CreateLog(data)
    local go = Instantiate(self.mPrefab)
    go.name = #self.mCellList+1
    TransTool.AddChild(self.mTable.transform, go.transform)
    go:SetActive(true)
    local lab = ComTool.GetSelf(UILabel, go)
    lab.text = self:SetText(data)
    UITool.SetLsnrSelf(go, self.OnClick, self, "", false)
    table.insert(self.mCellList, lab)
    self.mTable.repositionNow = true
end

function M:OnClick(go)
    if LuaTool.IsNull(go) then return end
    local lab =self.mCellList[tonumber(go.name)]
    local url= lab:GetUrlAtPosition(UICamera.lastWorldPosition)
    if StrTool.IsNullOrEmpty(url)then return end	
    --iTrace.Error("--->>", url)	
    local list = StrTool.Split(url, "_")	
    FamilyEscortMgr:ClickUrl(list[1], list[2], list[3])
end

function M:UpdateScrollbars()
    if not self.mTimer then
        self.mTimer = ObjPool.Get(iTimer)
        self.mTimer.seconds = 0.05
        self.mTimer.complete:Add(self.CompleteCb, self)
    end
    self.mTimer:Start()
end

function M:CompleteCb()
    if not self.mTable then return end
    self.mTable:Reposition()
    local len = self:GetActiveCellsCount()
    self.mSlider.value = len < 6 and 0 or 1
	self.mScrollView:UpdateScrollbars()
end

function M:GetActiveCellsCount()
    local list = self.mCellList
    local len = 0
    for i=1,#list do
        if list[i].gameObject.activeSelf then
            len = len + 1 
        end
    end
    return len
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

function M:Dispose()
    if self.mTimer then 
        self.mTimer:AutoToPool()
        self.mTimer = nil
    end
    TableTool.ClearDic(self.mCellList)
    TableTool.ClearUserData(self)
end

return M