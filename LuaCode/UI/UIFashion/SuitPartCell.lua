SuitPartCell = Super:New{Name = "SuitPartCell"}

local M = SuitPartCell
--当前选中套装
M.curSuitPart = nil;
M.selectPartId = nil;
M.eClick = Event();

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local FG = TransTool.FindChild
    local G = ComTool.Get
    local trans = go.transform
    self.go = go
    self.bg = FG(trans, "bg")
    self.lock = FG(trans, "Lock")
    self.highlight = FG(trans, "Highlight")
    self.active = FG(trans, "Active")
    self.name = G(UILabel, trans, "Name")
    self.icon = G(UITexture, trans, "bg/Icon")
    UITool.SetLsnrSelf(go, self.OnClick, self,nil, false)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateIcon()
    self:UpdateLock()
    self:UpdateGray()
    self:UpdateActive()
    self:SelectCell()
end

function M:UpdateName()
    self.name.text = self.data.name;
end

function M:UpdateIcon()
    local data = self.data;
    local icon = User.MapData.Sex==1 and data.mIcon or data.wIcon
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:UpdateActive()
    self.active:SetActive(self.data.isActive)
end

function M:UpdateLock()
    self.lock:SetActive(not self.data.isActive)
end

function M:UpdateGray()
    if self.data.isActive then
        UITool.SetAllNormal(self.bg)
    else
        UITool.SetAllGray(self.bg)
    end
end

function M:OnClick()
    if self.data then
        M.eClick(self.data)
        self:Select();
    end
end

--选择格子
function M:SelectCell()
    if M.selectPartId == nil then
        M.selectPartId = self.data.baseId;
    end
    if M.selectPartId == self.data.baseId then
        self:OnClick();
    end
end

function M:Select()
    self:ClearLastSelect();
    self:UpdateHighlight(true);
    M.curSuitPart = self;
end

function M:ClearLastSelect()
    if M.curSuitPart ~= nil then
        M.curSuitPart:UpdateHighlight(false);
    end
end

function M:UpdateHighlight(state)
    self.highlight:SetActive(state)
end

function M:Clear()
    self:ClearLastSelect();
    M.selectPartId = nil;
    M.curSuitPart = nil;
end

function M:Dispose()
    self.data = nil
    self:Clear();
    TableTool.ClearUserData(self)
    AssetTool.UnloadTex(self.texList)
end

return M