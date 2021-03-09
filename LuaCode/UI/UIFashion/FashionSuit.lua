FashionSuit = Super:New{Name = "FashionSuit"}

require("UI/UIFashion/SuitCell")

local M = FashionSuit
M.offsetPos = Vector2.New(0,95)

function M:Ctor()
    self.cellList = {}
end

function M:Init(trans)
    local CG = ComTool.Get
    local TF = TransTool.Find
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick

    self.go = trans.gameObject
    self.svTrans = TF(trans,"ScrollView")
    local panelCom = CG(UIPanel,trans,"ScrollView")
    self.panelHeight = panelCom:GetViewSize().y;
    self.panelCom = CG(UIPanel,trans,"ScrollView")
    self.grid = CG(UIGrid, trans, "ScrollView/Grid")
    self.prefab = FC(self.grid.transform, "Cell") 
    self.prefab:SetActive(false)

    SC(trans,"Down",trans.name,self.DownClick,self)
end

function M:SetActive(state)
    self.go:SetActive(state)
    if state then
        self:UpdateData()
    end
end

function M:IsActive()
    return self.go.activeSelf
end

function M:UpdateRedPoint()
    local list = self.cellList
    for i=1,#list do
        list[i]:UpdateRedPoint()
    end
end

function M:Refresh()
    self:UpdateData()
end

function M:UpdateData()
    local data = FashionMgr:GetSuitInfo()
    if not data then return end
    local list = self.cellList
    local len = #data
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
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform, go.transform)
            local cell = ObjPool.Get(SuitCell)
            cell:Init(go)
            cell:SetActive(true)
            cell:UpdateData(data[i])
            table.insert(self.cellList, cell)
        end
    end
    self.grid:Reposition()
end

--点击下拉按钮
function M:DownClick()
    local svPos = self.svTrans.localPosition;
    local svOffset = Vector2.New(svPos.x,svPos.y);
    svOffset = svOffset + M.offsetPos;

    local panelPos = self.panelCom.clipOffset;
    panelPos = panelPos - M.offsetPos;

    local posY = self:CalPos(panelPos);
    panelPos.y = -posY;
    svOffset.y = posY;
    
    self.svTrans.localPosition = svOffset;
    self.panelCom.clipOffset = panelPos;
end

--计算格子位置
function M:CalPos(panelPos)
    local count = #self.cellList;
    local maxShow = self.panelHeight/M.offsetPos.y;
    if count <= maxShow then
        return 0;
    end
    local gridHeight = self.grid.cellHeight;
    local svHeight = self.panelHeight;
    local heightPos = count * gridHeight - svHeight + 8;
    local offset = heightPos + panelPos.y;
    if offset <= 0 then
        local offsetY = count * M.offsetPos.y - svHeight;
        return offsetY;
    else
        local panelPos = self.panelCom.clipOffset;
        local num = math.floor(-panelPos.y/M.offsetPos.y);
        local offsetY = (num + 1) * M.offsetPos.y;
        return offsetY;
    end
end

function M:Dispose()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M