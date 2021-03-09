FashionList = Super:New{Name = "FashionList"}

require("UI/UIFashion/FashionCell")

local M = FashionList

M.eClickFashion = Event()

function M:Ctor()
    self.cellList = {}
end

function M:Init(root)
    local G = ComTool.Get

    self.go = root.gameObject
    self.scorll = G(UIScrollView, root, "ScrollView")
    self.sViewPanel = G(UIPanel, root, "ScrollView")
    self.grid = G(UIGrid, root, "ScrollView/Grid")
    self.cell = TransTool.FindChild(self.grid.transform, "Cell")
    self.cell:SetActive(false)
    self.title = G(UISprite, root, "Title")
    self.sViewPos = self.scorll.transform.localPosition
	self.sViewPosY = self.sViewPos.y
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:CreateCell(data, _type)
    local go = Instantiate(self.cell)
    TransTool.AddChild(self.grid.transform, go.transform)
    local fashionCell = ObjPool.Get(FashionCell)
    fashionCell:Init(go)
    fashionCell:SetHandler(self.Handler, self)
    fashionCell:UpdateCell(data, _type)
    table.insert(self.cellList, fashionCell)
end

function M:UpdateTitle(_type)
    self.title.spriteName = tostring(_type)
end

function M:UpdateData(_type)
    self:UpdateTitle(_type)
    self:UpdateCell(_type)
end


function M:UpdateCell(_type)
    local data = FashionMgr:GetFashionInfo(_type)
    if not data then return end
    local list = self.cellList
    local len = #data
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateCell(data[i], _type)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateCell(data[i], _type)
        end
    end
    self.grid:Reposition()
end

function M:ResetScrollView()
    self.scorll:ResetPosition()
end

function M:SetShow(baseId)
    if baseId then
        local list = self.cellList
        for i=1,#list do
            if list[i]:ActiveSelf() and list[i].data.baseId == baseId then
                self:UpdateScrollView(i)
                list[i]:OnClick()
                return
            end
        end
    end
    self:SetDefShow()
    self:ResetScrollView()
    self:UpdateScrollView(1)
end

function M:SetDefShow()
    if self.cellList[1] then
        self.cellList[1]:OnClick()
    end
end

function M:UpdateScrollView(index)
    index = math.ceil(index/2)
    local y = (index-1)*194
    self.scorll.transform.localPosition = Vector3(self.sViewPos.x, y, self.sViewPos,z)
    self.sViewPanel.clipOffset = Vector2(0, -y)
end

function M:SetHighlight(baseId)
    local list = self.cellList
    local len = #list
    for i=1,len do
        list[i]:SetHighlight(list[i].data.baseId == baseId)
    end
end

function M:Handler(baseId)
    self:SetHighlight(baseId)
    M.eClickFashion(baseId)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.cellList)
end

return M