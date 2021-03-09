UISpiritCompose = UIBase:New{Name = "UISpiritCompose"}

require("UI/SpiritCompose/ComposeCell")

local My = UISpiritCompose

My.Quality = {"蓝色", "橙色", "红色", "全部品质"}
My.Star = {"一阶", "二阶", "三阶", "四阶","五阶","六阶","七阶","全部等阶"}

My.cellList = {}
My.selectList = {}
My.showCompExp = 0

function My:InitCustom()
    local trans = self.root
    self.root.transform.localPosition = Vector3.New(0,0,1100)
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.quality = G(UIPopupList, trans, "QualityMenu")
    self.labQua = G(UILabel, self.quality.transform, "Label")
    self.star = G(UIPopupList, trans, "StepMenu")
    self.labStar = G(UILabel, self.star.transform, "Label")
    self.sView = G(UIScrollView, trans, "ScrollView")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.expLab = G(UILabel,trans,"comLab/expLab")
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)

    self.composeBtn = FC(trans, "Button")
    self.btnClose = FC(trans, "closeBtn")
    S(self.composeBtn,self.OnComposeBtn,self)
    S(self.btnClose, self.Close, self)

    self:InitPopupList(self.quality, self.Quality)
    self:InitPopupList(self.star, self.Star)

    
    EA(self.quality.onChange, EC(self.OnQuaSelect, self))
    EA(self.star.onChange, EC(self.OnStarSelect, self))
    
    -- self:OpenCompose(#self.Quality,#self.Star)
    self:OpenCompose(1,#self.Star)
    self:SetEvent("Add")
end

function My:SetEvent(fn)
    local mgr = SpiritGMgr
	mgr.eUpdateBagInfo[fn](mgr.eUpdateBagInfo, self.RefreshBag, self)
	mgr.eUpdateComposeInfo[fn](mgr.eUpdateComposeInfo, self.OnComposeInfo, self)
    -- RobberyMgr.eUpdateSpiRefInfo[fn](RobberyMgr.eUpdateSpiRefInfo, self.SetSpProp, self)
end

function My:InitPopupList(popupList, list)
    popupList:Clear()
    for i=1,#list do
        popupList:AddItem(list[i])
    end
    popupList.value = list[#list]
end

function My:UpdateData(data)
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
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(ComposeCell)
            item:Init(go)
            item.eClick:Add(self.OnClick,self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.sView:ResetPosition()
    self.grid:Reposition()
end

function My:ClearSelectData()
    self.showCompExp = 0
    self.expLab.text = self.showCompExp
    TableTool.ClearDic(self.selectList)
end

function My:OnClick(isSelect, data)
    if isSelect then
        TableTool.Add(self.selectList, data, "id")
    else
        TableTool.Remove(self.selectList, data, "id")
    end
    self:ShowComposeExp(isSelect,data)
end

function My:SelectAll()
    self:ClearSelectData()
    local list = self.cellList
    for i=1,#list do
        local quality = list[i].data.quality
        if list[i]:IsActive() and quality == 2 then
            list[i]:SetHighlight(true)
            table.insert(self.selectList, list[i].data)
            self:ShowComposeExp(true,list[i].data)
        end
    end
end

--显示分解将要获得的经验
function My:ShowComposeExp(isSelect,data)
    local showExp = self.showCompExp
    local equipId = data.typeId
    local lv = data.level
    local curLvExp = data.advExp
    local lvExp = 0
    local strengCfg = SpiritEStrengthCfg[lv]
    if strengCfg then
        lvExp = strengCfg.costExp
    end
    equipId = tostring(equipId)
    local equipCfg = SpiritEquipCfg[equipId]
    local comExp = equipCfg.getExp
    local add = comExp + lvExp + curLvExp
    if isSelect then
        showExp = showExp + add
    else
        showExp = showExp - add
    end
    self.showCompExp = showExp
    self.expLab.text = self.showCompExp
end

--分解返回
function My:OnComposeInfo()

end

--装备刷新
function My:RefreshBag()
    self:ClearSelectData()
    self:OnQuaSelect()
    self:OnStarSelect()
end

--品质筛选
function My:OnQuaSelect()
    local curQ = self:GetIndex(self.Quality, self.quality.value)
    if curQ == #self.Quality then
        curQ = SpiritGMgr.All
    elseif curQ == 1 then
        curQ = 2
    elseif curQ == 2 then
        curQ = 4
    elseif curQ == 3 then
        curQ = 5
    end
    self.curQuality = curQ
    self:Refresh(1)
end

--等阶筛选
function My:OnStarSelect()
    local curS = self:GetIndex(self.Star, self.star.value)
    if curS == #self.Star then
        curS = SpiritGMgr.All
    end
    self.curStar = curS
    self:Refresh(2)
end

function My:Refresh()
    local data = nil
    local data = SpiritGMgr:GetBagEquipQS(self.curQuality,self.curStar)
    self:UpdateData(data)
    self:SelectAll()
end

function My:OpenCompose(quality, star) 
    self.part = nil
    self:UpdatePopVal(quality, star)
    self:Refresh(1)
end

function My:UpdatePopVal(quality, star)
    quality = quality or #self.Quality
    star = star or #self.Star
    self.labQua.text = self.Quality[quality]
    self.labStar.text = self.Star[star]
    local index = self:GetIndex(self.Quality, self.labQua.text)
    self.curQuality = self:SwitchQ(index)
    self.curStar = self:GetIndex(self.Star, self.labStar.text)
end

function My:SwitchQ(index)
    local curQ = 0
    if index == #self.Quality then
        curQ = SpiritGMgr.All
    elseif index == 1 then
        curQ = 2
    elseif index == 2 then
        curQ = 4
    elseif index == 3 then
        curQ = 5
    end
    return curQ
end

function My:GetIndex(list, val)
    local len = #list
    local index = SpiritGMgr.All
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

--点击分解
function My:OnComposeBtn()
    local list = self.selectList
    local len = #list
    if len == 0 then
        UITip.Log("请选择分解材料")
        return
    end
    -- iTrace.Error("GS","len===",len)
    SpiritGMgr:ReqSpiritEquipDecom(list)
end

function My:CloseCustom()

end

function My:DisposeCustom()
    self:SetEvent("Remove")
    self:ClearSelectData()
    self.curQuality = 0
    self.curStar = 0
    self.part = nil
    self.showCompExp = 0
    self.index = 1
    TableTool.ClearListToPool(self.cellList)
    -- TableTool.ClearUserData(self)
end

return My