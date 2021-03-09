UISkyMysterySealStrengthView = {}

local M = UISkyMysterySealStrengthView

function M:New(go)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealStrengthView"

    self.IsComplete = T(trans, "IsComplete")
    self.Icon = C(UISprite, trans, "Target/Icon", name, false)
    self.Word = C(UISprite, trans, "Target/Word", name, false)
    self.CostRoot = T(trans, "Cost")
    self.RateLab =C(UILabel, trans, "Cost/Rate", name, false)
    self.DesLab = C(UILabel, trans, "Des", name, false)
    self.StrengthBtn = T(trans, "GetBtn")
    self.Cell = ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(T(trans, "Cost/ItemRoot").transform)
    
    self.ChangeTip = T(trans, "ChangeTip")

    self.CurPros = {}
    self.NextPros = {}
    self:InitPros(self.CurPros, T(trans, "CurPro"), name)
    self:InitPros(self.NextPros, T(trans, "NextPro"), name)

    self.Eff = T(trans, "Target/Effect")

    self.Status = false

    UITool.SetLsnrSelf(self.StrengthBtn, self.OnClickStrengthBtn, self, nil, false)
    return self
end

function M:InitPros(info, go, name)
    local trans = go.transform
    local C = ComTool.Get
    info.Lv = C(UILabel, trans, "StrengthLv", name, false)
    info.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
    info.Pros = {}
    for i=1,10 do
        local pro = {}
        pro.Title = C(UILabel, trans,string.format("ScrollView/Grid/Pro%s", i), name, false)
        pro.Value = C(UILabel, trans,string.format("ScrollView/Grid/Pro%s/Label", i), name, false)
        table.insert(info.Pros,  pro) 
    end
end
-----------------------------------------------------
function M:ShowEffect()
    self.Eff:SetActive(true)
end

function M:UpdateData()
    local type = SMSMgr.CurPage
    local infos = SMSMgr.Infos[type]
    if not infos then return end
    for i=0,9 do
        local info = infos[i]
        if info and info.Pro and info.Pro.Item then
            self:UpdateInfoData(info)
            SMSControl:SetShowViewSelect(info.OpenTemp.index)
            return
        end
    end
end

function M:UpdateHoldInfo(info)
    if self.Info.OpenTemp.id == info.OpenTemp.id then
        self:UpdateInfoData(info)
    end
end

function M:UpdateInfoData(info)
    self:Reset()
    self.Info = info
    local index = info.OpenTemp.index
    local isOpen = info.Pro ~= nil
    self:UpdateIcon(index)
    self:UpdateWord(index)

    local slv = 0
    if info.Pro then slv = info.Pro.StrengthLv end
    local proTemp = SMSProTemp[tostring(info.Pro.Item.type_id)]
    local temp, nTemp = nil 
    if proTemp and proTemp.limit >=0 then 
        temp, nTemp =self:UpdateStrengthLv(index, slv)
    end
    self:UpdateCell(nTemp)
    local isFull = isOpen == true and nTemp == nil
    self.CostRoot:SetActive(not isFull)
    self.StrengthBtn.gameObject:SetActive(not isFull)
    self.DesLab.gameObject:SetActive(not isFull)
    self.IsComplete:SetActive(isFull and temp ~= nil)
end

function M:UpdateIcon(index)
    self.Icon.spriteName = string.format("tianji_bagua_%s",index)
end

function M:UpdateWord(index)
    local cur = SMSMgr.CurPage
    local page = "yang"
    if cur ~= 1 then page = "yin" end
    self.Word.spriteName = string.format("%s%s_bg",page, index)
    self.Word:MakePixelPerfect()
end

function M:UpdateStrengthLv(index, lv)
    if not lv then lv = 0 end
    local nextLv = lv + 1
    local temp = SMSStrengthTemp[tostring(10000+index*1000 + lv)]
    local nextTemp = SMSStrengthTemp[tostring(10000+index*1000 + nextLv)]
    if temp and nextTemp then
        local info = self.Info
        if info and info.Pro and info.Pro.Item then
            local pTemp = SMSProTemp[tostring(info.Pro.Item.type_id)]
            if pTemp and pTemp.limit <= temp.lv then
                temp = SMSStrengthTemp[tostring(10000+index*1000 + pTemp.limit)]
                nextTemp = nil
                self:SetChangeTip(true)
            end
        end
    end
    if temp then
        self:UpdateStrengthPro(self.CurPros, temp, false)
    else
        local t = SMSStrengthTemp[tostring(10000+index*1000 + 1)]
        self:UpdateStrengthPro(self.CurPros, t, false, "0")
    end
    self:UpdateStrengthPro(self.NextPros, nextTemp, true)
    return temp, nextTemp
end

function M:UpdateStrengthPro(info, temp, isNext, str)
    info.Lv.gameObject:SetActive(isNext==false or(temp ~= nil and isNext == true))
    local lv = 0
    if temp and StrTool.IsNullOrEmpty(str) == true then lv = temp.lv end
    info.Lv.text = tostring(lv)
    if not temp then
        return
    end
    local list = SMSMgr.ProKeys
    local num = 1
    local pros = info.Pros
    for i=1,#list do
        local key = list[i]
        local pro = temp[key]
        if pro and pro ~= 0 then
            if num <= #pros then
                pros[num].Title.text = PropTool.GetName(key) 
                if StrTool.IsNullOrEmpty(str) == true then
                    pros[num].Value.text = pro
                else
                    pros[num].Value.text = str
                end
                pros[num].Title.gameObject:SetActive(true)
                num = num + 1
            end
        end 
    end
    info.Grid:Reposition()
end

function M:SetChangeTip(value)
    local tip = self.ChangeTip
    if tip then
        tip:SetActive(value)
    end
end

function M:UpdateCell(temp)

    if temp == nil then return end
    local item = ItemData[tostring(temp.cost_id)]
    if item then
        local count = SMSMgr.CostNum
        self.Status = count >= temp.cost_num
        local cell = self.Cell
        if cell then
            cell.trans.gameObject:SetActive(temp ~= nil)
            cell:UpData(item)
        end
        local lab = self.RateLab
        if lab then
            local value = count
            if count < temp.cost_num then
                value = string.format("[ff0000]%s[-]", value)
            else
                value = string.format("[ffffff]%s[-]", value)
            end
            lab.text = string.format("%s/%s",value,temp.cost_num)
        end
    end
end
-----------------------------------------------------

function M:OnClickStrengthBtn(go)
    if self.Status == false then
        UITip.Error("分解天机印获得强化所需消耗的物品")
        --SMSControl:OpenGetWay(go.transform.position)
        --[[
        local info = self.Info
        if info.OpenTemp.condition then
            local temp = info.OpenTemp
            local name = temp.name
            local copyTemp = CopyTemp[tostring(temp.condition)]
            local copy = ""
            if copyTemp then copy = copyTemp.name end
            MsgBox.ShowYes(string.format("当前选中的[00ff00]【%s】[-]未激活\n开启[00ff00]【%s】[-]后方能激活\n是否立即前往？",name, copy, layer),
            SMSControl.OpenGetWay, 
            SMSMgr, 
            "确定")
        end
        ]]--
        return
    end
    local info = self.Info
    if not info then
        UITip.Error("没有选中要强化的天机印")
        return 
    end
    if not info.Pro then
        UITip.Error("想要强化的天机印未解锁")
        return 
    end
    if not info.Pro.Item then
        UITip.Error("想要强化的天机印未镶嵌")
        return 
    end

    SMSNetwork:ReqPlaceRefineTos(SMSMgr.CurPage, info.OpenTemp.id)
end

function M:UpdateConsum()
    self:UpdateInfoData(self.Info)
end

function M:Reset()
    self.Info = nil
    self.IsComplete:SetActive(false)
    self:ResetPros(self.CurPros)
    self:ResetPros(self.NextPros)
    self:SetChangeTip(false)
end

function M:ResetPros(info)
    if not info then return end
    info.Lv.text = ""
    local len = #info.Pros
    if len > 0 then
        for i=1,len do
            info.Pros[i].Value.text = ""
            info.Pros[i].Title.text = ""
            info.Pros[i].Title.gameObject:SetActive(false)
        end
    end
end

function M:DestroyPros(info)
    if not info then return end
    TableTool.ClearDic(info)
end

function M:Dispose()
    self:DestroyPros(self.CurPros)
    self:DestroyPros(self.NextPros)
end

return M