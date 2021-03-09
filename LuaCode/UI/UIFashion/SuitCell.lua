SuitCell = Super:New{Name = "SuitCell"}

local M = SuitCell

M.eClick = Event()
--当前选中套装
M.curSuit = nil;
--选中套装ID
M.selectSuitId = nil;

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local FG = TransTool.FindChild
    local UC = UITool.SetLsnrClick;
    local G = ComTool.Get
    local trans = go.transform
    self.go = go
    self.bg = FG(trans, "bg")
    self.lock = FG(trans, "Lock")
    self.highlight = FG(trans, "Highlight")
    self.redPoint = FG(trans, "RedPoint")
    self.active = FG(trans, "Active")
    self.name = G(UILabel, trans, "Name")
    self.icon = G(UITexture, trans, "bg/Icon")
    self.Type = G(UISprite, trans,"Type")
    self.Progress = G(UILabel, trans, "Progress")
    UC(trans,"Container",trans.name,self.OnClick,self);
end

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateIcon()
    self:UpdateActive()
    self:UpdateLock()
    self:UpdateGray()
    self:UpdateType();
    self:UpdateProgress();
    self:UpdateRedPoint()
    self:SelectCell()
end

function M:UpdateName()
    self.name.text = self.data.name
end

function M:UpdateIcon()
    local icon = User.MapData.Sex==1 and self.data.mIcon or self.data.wIcon
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
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

function M:UpdateType()
    local name = nil;
    local type = self.data.type;
    if type == 1 then
        name = "taozhuang_text_tz";
    elseif type == 2 then
        name = "taozhuang_text_xianlv";
    end
    self.Type.spriteName = name;
end

function M:UpdateProgress()
    local allNum = #self.data.fashionList;
    if self.data.type == 2 then
        allNum = allNum * 2;
    end
    local activeNum = FashionHelper.GetAllSuitActNum(self.data);
    local text = string.format("(%d/%d)",activeNum,allNum);
    self.Progress.text = text;
end

function M:Select()
    if M.curSuit ~= nil then
        M.curSuit:UpdateHighlight(false);
    end
    self:UpdateHighlight(true);
    self:SetSelectID(self.data.id);
    M.curSuit = self;
end

function M:UpdateHighlight(state)
    self.highlight:SetActive(state)
end

function M:UpdateRedPoint()
    self.redPoint:SetActive(FashionMgr:GetSuitRedPoint(self.data.id))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:SetActive(state)
    self.go:SetActive(state)
end

--设置选中套装ID
function M:SetSelectID(suitId)
    if suitId == nil then
        return;
    end
    if type(suitId) ~= "number" then
        return;
    end
    M.selectSuitId = suitId;
end

--选择格子
function M:SelectCell()
    if M.selectSuitId == nil then
        M.selectSuitId = self.data.id;
    end
    if M.selectSuitId == self.data.id then
        self:OnClick();
    end
end

function M:OnClick()
    if self.data then
        M.eClick(self.data)
        self:Select();
    end
end

function M:Dispose()
    self.data = nil
    M.selectSuitId = nil;
    M.curSuit = nil;
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
end

return M