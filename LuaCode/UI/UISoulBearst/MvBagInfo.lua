MvBagInfo = Super:New{Name = "MvBagInfo"}

local M = MvBagInfo


M.Quality = {"白色", "蓝色", "紫色", "橙色", "红色", "粉色", "全部品质"}
M.Star = {"一星", "二星", "三星", "全部星级"}

M.eClick = Event()

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback

    self.go = go

    self.title = G(UILabel, trans, "Title")
    self.quality = G(UIPopupList, trans, "Quality")
    self.labQua = G(UILabel, self.quality.transform, "Label")
    self.star = G(UIPopupList, trans, "Star")
    self.labStar = G(UILabel, self.star.transform, "Label")
    self.sView = G(UIScrollView, trans, "ScrollView")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.panel = G(UIPanel, trans, "ScrollView")
    self.pos = self.sView.transform.localPosition

    SC(trans, "BtnGetEquip", self.Name, self.OnGetEquip, self)
    SC(trans, "BtnClose", self.Name, self.Close, self)


    self:InitPopupList(self.quality, self.Quality)
    self:InitPopupList(self.star, self.Star)

    EA(self.quality.onChange, EC(self.OnQuaSelect, self))
    EA(self.star.onChange, EC(self.OnStarSelect, self))
end

function M:InitPopupList(popupList, list)
    popupList:Clear()
    for i=1,#list do
        popupList:AddItem(list[i])
    end
    popupList.value = list[#list]
end

function M:UpdateData(data)
    local len = #data
    local list = self.cellList
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
            local item = ObjPool.Get(SBCell)
            item:InitLoadPool(self.grid.transform)
            item:SetTip(true, true, true)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self:ResetPosition()
end

function M:ResetPosition()
    self.grid:Reposition()
    self.sView:ResetPosition()
    self.sView.transform.localPosition = self.pos
    self.panel.clipOffset = Vector2(0,0)
end


function M:OnQuaSelect()
    self.curQuality = self:GetIndex(self.Quality, self.quality.value)
    self:Refresh()
end

function M:OnStarSelect()
    self.curStar = self:GetIndex(self.Star, self.star.value)
    self:Refresh()
end

function M:Refresh()
    local data = nil
    if not self.part then
        data = SoulBearstMgr:GetBagEquipQS(self.curQuality, self.curStar)
    else
        data = SoulBearstMgr:GetBagEquipPQ(self.part, self.curQuality)
    end
    self:UpdateData(data)
end

function M:TryOpen(part, quality)
    self.part = part
    self.curQuality = quality
    local data = SoulBearstMgr:GetBagEquipPQ(part, quality)
    if #data > 0 then
        self:SetPopActvie(false)
        self:UpdateData(data)
        self:UpdateTitle(part)
        self:SetActive(true)
        return true
    end
    return false
end

function M:UpdateTitle(part)
    self.title.text = string.format("%s装备", SoulBearstMgr.PartName[part])
end

function M:Open(quality, star) 
    self.part = nil
    self:UpdatePopVal(quality, star)
    self:Refresh()
    self:SetPopActvie(true)
    self:SetActive(true)
end

function M:SetPopActvie(state)
    self.quality.gameObject:SetActive(state)
    self.star.gameObject:SetActive(state)
    self.title.gameObject:SetActive(not state)
end

function M:UpdatePopVal(quality, star)
    quality = quality or #self.Quality
    star = star or #self.Star
    self.labQua.text = self.Quality[quality]
    self.labStar.text = self.Star[star]
    self.curQuality = self:GetIndex(self.Quality, self.labQua.text)
    self.curStar = self:GetIndex(self.Star, self.labStar.text)
end


function M:GetIndex(list, val)
    local len = #list
    local index = SoulBearstMgr.All
    for i=1,len do
        if list[i] == val then
            if i < len then
                index = i
            end
            break
        end
    end
    return index
end

function M:Close()
    self.part = nil
    self:SetActive(false)
    self.eClick()
end

function M:OnGetEquip()
    BossHelp.OpenBoss(5)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Dispose()
    self.curQuality = 0
    self.curStar = 0
    self.part = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M