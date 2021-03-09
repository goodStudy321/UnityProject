UISkyMysterySealTip = Super:New{Name="UISkyMysterySealTip"}

local M = UISkyMysterySealTip

function M:Init(go, showBtn)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealTip"
    self.Active = T(trans, "Active")
    self.Active:SetActive(not showBtn)
    self.Cell = ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(T(trans, "ItemRoot").transform)
    self.Cell.IsClick = false
    self.Quality = C(UISprite, trans, "Quality", name, false)
    self.NameLab = C(UILabel, trans, "Name", name, false)
    self.PosLab = C(UILabel, trans, "Pos", name, false)
    self.ScoreLab = C(UILabel, trans, "Score", name, false)
    self.SV = C(UIScrollView, trans, "ScrollView", name, false)
    self.Panel = C(UIPanel, trans, "ScrollView", name, false)
    self.BPGrid = C(UIGrid, trans, "ScrollView/Root/BasePro/Grid", name, false)
    self.labWorth = C(UILabel, trans, "labWorth")
    self.BPPros = {}
    for i=1,11 do
        table.insert(self.BPPros, C(UILabel, trans, string.format("ScrollView/Root/BasePro/Grid/%s",i)))
    end
    self.SuitRoot = T(trans, "ScrollView/Root/SuitPro")
    self.SuitTitle = C(UILabel, trans, "ScrollView/Root/SuitPro/Title", name, false)
    --self.SuitGrid = C(UIGrid, trans, "ScrollView/Root/SuitPro/Grid", name, false)
    self.SuitPro = {}
    for i=1,11 do
        local item = ObjPool.Get(UISkyMysterySealSuitItem)
        item:Init(T(trans, string.format("ScrollView/Root/SuitPro/Root/%s", i)))
        table.insert(self.SuitPro, item)
    end
    self.SkillRoot = T(trans,"ScrollView/Root/Skill/")
    self.Skills = {}
    for i=1,5 do
        local info = {}
        info.Name = C(UILabel, trans, string.format("ScrollView/Root/Skill/Root/Skill%s", i), name, false)
        info.Des = C(UILabel, trans, string.format("ScrollView/Root/Skill/Root/Skill%s/Label", i), name, false)
        info.Root = info.Name.transform
        table.insert(self.Skills, info)
    end

    self.SPanelPos = self.Panel.transform.localPosition
    if showBtn == true then
        self.Contrast = C(UISprite, trans, "Contrast", name, false)
        self.TimeRoot = T(trans ,"Timer")
        
        self.TimeRoot:SetActive(false);
        
        self.Timer = C(UILabel, trans, "Timer/Label", name, false)
        self.OpenBtn = T(trans, "OpenBtn")
        self.InlayBtn = T(trans, "InlayBtn")
        self.AuctionBtn = T(trans, "AuctionBtn")
        self.ReplaceBtn = T(trans, "ReplaceBtn")
        self.StrengthBtn = T(trans, "StrengthBtn")
        self.UnloadBtn = T(trans, "UnloadBtn")
    
        self:SetBtnEvent(self.OpenBtn)
        self:SetBtnEvent(self.InlayBtn)
        self:SetBtnEvent(self.AuctionBtn)
        self:SetBtnEvent(self.ReplaceBtn)
        self:SetBtnEvent(self.StrengthBtn)
        self:SetBtnEvent(self.UnloadBtn)
    end
    self.ScoreLimit = 0
	return self
end

function M:SetBtnEvent(btn)
    if btn then
        UITool.SetLsnrSelf(btn, self.OnClickBtn, self, nil, false)
    end
end

-----------------------------------------------------
--value1 true(背包) false(当前镶嵌)
--isOpen true(已开孔) false(需要开孔)
--compare true(有参照) false(可镶嵌)
--AllClose true(全关)
function M:UpdateData(item, value1, value2, compare,AllClose)
    self:ResetSVPos()
    self.Item = item
    if not item then return end
    local temp = nil
    if item.Name == "PropTb" then 
        temp = SMSProTemp[tostring(item.type_id)]
    else
        temp = SMSProTemp[tostring(item.id)]
    end
    if not temp then return end
    self.Temp = temp
    local name = temp.name
    local qua = temp.quality
    self:UpdateCell(item)
    self:UpdateQuality(qua)
    self:UpdateNameLab(name, qua)
    self:UpdatePosLab(name, qua)
    self:UpdateScoreLab(temp)
    if item.Name == "PropTb" and value1 == true and AllClose ~= true then 
       -- self:UpdateTimer()
    end
    local y = self:UpdatePros(temp)
    local list = SMSMgr:GetSuitProTempList(temp)
    local height = self:UpdateSuit(list, y)
    if temp.index == 0 then
        height, pos = self:UpdateSkills(temp.skills, height + math.abs(y))
        height = height + self:UpdateSkillEff(temp.skills, temp.skillEff, pos)
    end
    self:UpdateBtns(value1, value2, compare,AllClose)
    if self.SV then
        self.SV.isDrag = height > 340
    end
    local worth = 0
    local cost = 0
    if self.Item.type_id then
        worth = ItemData[tostring(self.Item.type_id)].worth
        cost = ItemData[tostring(self.Item.type_id)].cost
    elseif self.Item.worth ~= 0 then
        worth = self.Item.worth
        cost = self.Item.cost
    end
    self.labWorth.gameObject:SetActive(true)
    if SkyMysteryTip.isInWarehouse then
        self.labWorth.text = "[F4DDBDFF]兑换积分：[-][ffe9bd]"..cost
    else
        self.labWorth.text = "[F4DDBDFF]仓库积分：[-][ffe9bd]"..worth
    end
    self:SetActive(true)
end

function M:UpdateCell(item)
    if item.Name == "PropTb" then 
        self.Cell:UpData(item.type_id)
    else
        self.Cell:UpData(item.id)
    end
end

function M:UpdateQuality(qua)
    self.Quality.spriteName = string.format("cell_a0%s", qua)
end

function M:UpdateNameLab(str, qua)
    local item = self.Item
    if item.Name == "PropTb" then
        self.NameLab.text = string.format("%s%s[-]", UIMisc.LabColor(qua), str)
    else
        self.NameLab.text = string.format("%s%s[-]", UIMisc.LabColor(qua), str)
    end
end

function M:UpdatePosLab(str)
    local strs = StrTool.Split(str, ".")
    if strs then
        self.PosLab.text = strs[2]
    end
end

function M:UpdateScoreLab(temp)
    local total = PropTool.GetFight(temp, SMSMgr.ProKeys)
    self.ScoreLimit = math.floor(total)
    self.ScoreLab.text = tostring(math.floor(total))
end

function M:UpdateContrast(score)
    local sprite = self.Contrast
    self.Status = self.ScoreLimit > score
    if sprite then
        local name = "icon_rside"
        if not self.Status then
            name = "red_side"
        end
        sprite.spriteName = name
        sprite.gameObject:SetActive(SMSMgr.CurToggle ~= 3 and self.ScoreLimit ~= score)
    end
end

function M:UpdatePros(temp)
    local list = SMSMgr.ProKeys
    local num = 1
    for i=1,#list do
        local key = list[i]
        local pro = temp[key]
        if pro and pro ~= 0 then
            if i <= #self.BPPros then
                self.BPPros[num].text = string.format("[F4DDBD]%s %s[-]", PropTool.GetName(key), math.floor(pro))
                self.BPPros[num].gameObject:SetActive(true)
                num = num + 1
            end
        end 
    end
    self.BPGrid:Reposition()
    return self.BPGrid.transform.localPosition.y - num - 50
end

function M:UpdateSuit(list, y)
    local suit = self.SuitRoot
    if suit then
        suit:SetActive(list ~= nil)
        if list ~= nil then
            local pos = suit.transform.localPosition
            pos.y = y
            suit.transform.localPosition = pos
        end
    end
    if list == nil then return 0 end
    local len = #list
    local limit = 0
    local temp = nil
    local aNum = 0
    local iLen = #self.SuitPro
    local pos = Vector3.zero
    for i=1, len do
        if iLen >= len then
            local info = list[i]
            if info then
                self.SuitPro[i].ActiveStatus = info.Status
                self.SuitPro[i]:UpdatePos(pos)
                self.SuitPro[i]:UpdateData(info.Temp)
                pos.y = pos.y - self.SuitPro[i].Height - 50
                if limit < info.Temp.num then
                    limit = info.Temp.num
                    temp = info.Temp
                end
            end
        end
    end
    local status, aNum = false, 0
    if temp then
        status, aNum = SMSMgr:GetSuitActiveStatus(temp, limit)
    end
    self.SuitTitle.text = string.format("套装效果（%s/%s）", aNum, limit)
    return math.abs(y) + math.abs(pos.y)
end

function M:UpdateBtns(value1, value2,  value3,AllClose)
    local select = SMSMgr.CurToggle ~=  3
    self:SetBtnActive(self.OpenBtn, value1 == true and value2 == false and select == true and AllClose~=true)
    self:SetBtnActive(self.InlayBtn, value1 == true and value2 == true and value3 == false and select == true and AllClose~=true)
    self:SetBtnActive(self.AuctionBtn, value1 == true and SMSMgr:IsAuction(self.Item) == true and AllClose ~= true)
    self:SetBtnActive(self.ReplaceBtn, value1 == true and value2 == true and value3 == true and select == true and AllClose~=true)
    self:SetBtnActive(self.StrengthBtn, value1 == false and select == true and AllClose~=true)
    self:SetBtnActive(self.UnloadBtn, value1 == false and select == true and AllClose~=true)
end

function M:UpdateTimer()
    if self.TimeRoot then
        self.TimeRoot:SetActive(SMSMgr:IsAuction(self.Item))
    end
    if self.Timer then
        self.Timer.text = SMSMgr:ShowWhetherLimit(self.Item)
    end
end

function M:UpdateSkills(skills, height)
    local len = #skills
    local skillItems = self.Skills
    local iLen = #skillItems
    local pos = Vector3.zero
    for i=1,len do
        if i <= iLen then
            local skillTemp = SkillLvTemp[tostring(skills[i])]
            if skillTemp and skillItems[i] then
                skillItems[i].Root.localPosition = pos
                skillItems[i].Root.gameObject:SetActive(true)
                skillItems[i].Name.text = skillTemp.name
                skillItems[i].Des.text = string.format("%s",skillTemp.desc)
                pos.y = pos.y - skillItems[i].Name.height - skillItems[i].Des.height
            end
        end
    end
    local root = self.SkillRoot
    if root then 
        root.transform.localPosition = Vector3.New(0,-height,0)
        root:SetActive(len > 0) 
    end
    return height + pos.y, pos
end

function M:UpdateSkillEff(skills, eff, pos)
    local sLen = 0
    if skills ~= nil then sLen = #skills end
    local height = 0
    local cfg = SMSMgr.GloblCfg
    if cfg then
        local skillItems = self.Skills
        local iLen = #skillItems
        local i = sLen + 1
        if i <= iLen then
            if skillItems[i] then
                pos.y = pos.y - 15
                skillItems[i].Root.localPosition = pos
                skillItems[i].Root.gameObject:SetActive(true)
                skillItems[i].Name.text = cfg.Value4[1].s
                skillItems[i].Des.text = cfg.Value5
                height = skillItems[i].Name.height + skillItems[i].Des.height
            end
        end
    end
    return height
end
-----------------------------------------------------

function M:OnClickBtn(go)
    local name = go.name
    local type = SMSMgr.CurPage
    local item = self.Item
    local temp = self.Temp
    local info = nil
    local id = nil
    if temp then 
       info = SMSMgr:GetInfoForIndex(temp.index)
       if info then id = info.OpenTemp.id end
    end

    if name == self.OpenBtn.name then
        local temp = info.OpenTemp
        local name = temp.name
        local copyTemp = CopyTemp[tostring(temp.condition)]
        local copy = ""
        if copyTemp then copy = copyTemp.name end
        MsgBox.ShowYes(string.format("当前选中的[00ff00]【%s】[-]未激活\n开启[00ff00]【%s】[-]后方能激活\n是否立即前往？",name, copy, layer),
        SMSControl.OpenCopyUI, 
        SMSMgr, 
        "确定")
    elseif name == self.InlayBtn.name then
        if id and item then
            if SMSMgr:IsAuction(item) == true then
                UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
            else
                SMSNetwork:ReqPlaceOperateTos(type, id, item.id ,1)
            end
        end
    elseif name == self.AuctionBtn.name then
        if SMSMgr:IsAuction(item) == true then
            UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
        end  
    elseif name == self.ReplaceBtn.name then
        if SMSMgr:IsAuction(item) == true then
            UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
        else
            if self.Status then
                SMSNetwork:ReqPlaceOperateTos(type, id, item.id, 2)
            else
                SMSControl:HoldControl(type, id, item.id, 2)
            end  
        end
    elseif name == self.StrengthBtn.name then
        SMSControl:ShowStrengthView(info)
    elseif name == self.UnloadBtn.name then
        SMSControl:HoldControl(type, id, item.id, 0)
    end
    SMSControl:ResetTipView()
end

function M:ShelfTipCB(name)
    local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(self.Item)
	end
end
-----------------------------------------------------

function M:UpdatePos(pos)
    self.Root.transform.localPosition = pos
end

function M:SetBtnActive(btn, bool)
    if  LuaTool.IsNull(btn)==false then
        btn:SetActive(bool)
    end
end

function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    self:ResetSVPos()
    self:ResetSkills()
    self.ScoreLimit = 0
    self.NameLab.text = ""
    self.PosLab.text = ""
    self.ScoreLab.text = ""
    if LuaTool.IsNull(self.Contrast) == false then self.Contrast.gameObject:SetActive(false) end
    self:SetBtnActive(self.OpenBtn, false)
    self:SetBtnActive(self.InlayBtn, false)
    self:SetBtnActive(self.AuctionBtn, false)
    self:SetBtnActive(self.ReplaceBtn, false)
    self:SetBtnActive(self.StrengthBtn, false)
    self:SetBtnActive(self.UnloadBtn, false)
    self:ResetPros()
    self:ResetSuitPro()
    self:SetActive(false)
end

function M:ResetSVPos()
	if self.SV then
        self.SV.isDrag = false
	end
    local panel = self.Panel
    if panel then
        panel.gameObject:SetActive(false)
        panel.transform.localPosition = self.SPanelPos
        panel.clipOffset = Vector3.zero
        panel.gameObject:SetActive(true)
    end
end

function M:ResetSkills()
    local skills = self.Skills
    if skills then
        local len = #skills
        for i=1,len do
            skills[i].Root.gameObject:SetActive(false)
        end
    end
    self.SkillRoot:SetActive(false)
end

function M:ResetPros()
    local items = self.BPPros
    if not items then return end
    local len = #items
    if len > 0 then
        for i=1,len do
            items[i].text = ""
            items[i].gameObject:SetActive(false)
        end
    end
end

function M:ResetSuitPro()
    local items = self.SuitPro
    if not items then return end
    local len = #items
    if len > 0 then
        for i=1,len do
            items[i]:Reset()
        end
    end
end

function M:DestroyPros()
    local items = self.BPPros
    if not items then return end
    local len = #items
    while len > 0 do
        local item = self.BPPros[len]
        table.remove(self.BPPros, len)
        item = nil
        len = #items
    end
end

function M:DestroySuitPro()
    local items = self.SuitPro
    if not items then return end
    local len = #items
    while len > 0 do
        local item = self.SuitPro[len]
        table.remove(self.SuitPro, len)
        item:Dispose()
        ObjPool.Add(item)
        len = #items
    end
end

function M:Dispose()
    self:DestroyPros()
    self:DestroySuitPro()
    self.OpenBtn = nil
    self.InlayBtn = nil
    self.AuctionBtn = nil
    self.ReplaceBtn = nil
    self.StrengthBtn = nil
    self.UnloadBtn = nil
end