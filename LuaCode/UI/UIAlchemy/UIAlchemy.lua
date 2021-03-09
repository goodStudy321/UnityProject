UIAlchemy = UIBase:New{Name = "UIAlchemy"}

require("UI/UIAlchemy/BestAlchemy")
require("UI/UIAlchemy/AlchemyStore")
require("UI/UIAlchemy/AlchemyToggle")

local M = UIAlchemy

M.mToggles = {}
M.mViews = {}

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get

    self.mGrid = G(UIGrid, trans, "ToggleGroup")
    self.mPrefab = FC(self.mGrid.transform, "Toggle")
    self.mPrefab:SetActive(false)

    --按顺序来，  顺序就是下标
    self:InitView(FestivalActMgr.BestAlchemy, BestAlchemy, FC(trans, "BestAlchemy"), FestivalActMgr.BestAlchemyInitRedPoint)
    self:InitView(FestivalActMgr.AlchemyStore, AlchemyStore, FC(trans, "Store"), FestivalActMgr.AlchemyStoreInitRedPoint)

    SC(trans, "BtnClose", self.Name, self.Close, self)

    self.mGrid:Reposition()

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    AlchemyMgr.eUpdateRedPoint[key](AlchemyMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
end

function M:UpdateRedPoint(type, state)
    if type ~= FestivalActMgr.BestAlchemy then return end
    local list = self.mToggles
    for i=1,#list do
        if list[i].Index == type then
            list[i]:SetRedPoint(state)
            break
        end
    end
end

function M:InitView(type, class, gameObject, redPointState)
    local info = FestivalActMgr:GetActInfo(type)
    if not info then return end
    local index = #self.mToggles + 1
    local go = Instantiate(self.mPrefab)
    go.name = index
    TransTool.AddChild(self.mGrid.transform, go.transform)
    local toggle = ObjPool.Get(AlchemyToggle)
    toggle:Init(go, type)
    toggle:SetName(info.title)
    toggle:SetActive(true)
    toggle:SetHighlight(false)
    toggle:SetRedPoint(redPointState)
    toggle.eClick:Add(self.OnToggle, self)
    self.mToggles[index] = toggle

    class:Init(gameObject)
    self.mViews[index] = class
end

function M:OnToggle(name)
    local index = tonumber(name)
    if self.mIndex and self.mIndex == index then return end
    local toggles = self.mToggles
    local views = self.mViews
    if self.mIndex then
        toggles[self.mIndex]:SetHighlight(false)
        views[self.mIndex]:Close()
    end
    self.mIndex = index
    toggles[index]:SetHighlight(true)
    if toggles[index].Index == FestivalActMgr.AlchemyStore then
        toggles[index]:SetRedPoint(false)
        FestivalActMgr:SetAlchemyStoreRedPoint(false)
    end
    views[index]:Open()
end

function M:OpenCustom()
    self:OnToggle(1)
end

function M:OpenTabByIdx(t1, t2, t3, t4)
    -- self:OnToggle(t1)
    local list = self.mToggles
    for i=1,#list do
        if list[i].Index == t1 then
            self:OnToggle(i)
            break
        end
    end
end

function M:DisposeViews()
    for k,v in pairs(self.mViews) do
        v:Dispose()
        self.mViews[k] = nil
    end
end

function M:DisposeCustom()
    self:DisposeViews()
    TableTool.ClearDicToPool(self.mToggles)
    self.mIndex = nil
end

return M