UISkyMysterySealOpen = {}

local M = UISkyMysterySealOpen

function M:New(go)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealOpen"

    self.Icon = C(UISprite, trans, "Target/Icon", name, false)
    self.Word = C(UISprite, trans, "Target/Word", name, false)
    self.CostRoot = T(trans, "Cost")
    self.RateLab =C(UILabel, trans, "Cost/Rate", name, false)
    self.DesLab = C(UILabel, trans, "Des", name, false)
    self.OpenBtn = T(trans, "OpenBtn")
    self.Cell = ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(T(trans, "Cost/ItemRoot").transform)

    self.Eff = T(trans, "Target/Effect")

    self.Status = false
    self.GetID = nil

    UITool.SetLsnrSelf(self.OpenBtn, self.OnClickOpenBtn, self, nil, false)
    return self
end
-----------------------------------------------------
function M:ShowEffect()
    self.Eff:SetActive(true)
end

function M:UpdateInfoData(info)
    self:Reset()
    self.Info = info
    local index = info.OpenTemp.index
    local isOpen = info.Pro ~= nil
    self:UpdateIcon(index)
    self:UpdateWord(index)
    self:UpdateDes(info.OpenTemp)
    self:UpdateCell(info.OpenTemp.item)
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

function M:UpdateDes(temp)
    self.DesLab.text = string.format("[F4DDBD]当前选中[00ff00][%s][-]未开启[-]",temp.name)
end

function M:UpdateCell(kv)
    if kv == nil then return end
    local item = ItemData[tostring(kv.k)]
    if item then
        self.GetID = kv.k
        local count = PropMgr.TypeIdByNum(kv.k)
        self.Status = count >= kv.v
        local cell = self.Cell
        if cell then
            cell.trans.gameObject:SetActive(kv ~= nil)
            cell:UpData(item)
        end
        local lab = self.RateLab
        if lab then
            local value = count
            if count < kv.v then
                value = string.format("[ff0000]%s[-]", value)
            else
                value = string.format("[ffffff]%s[-]", value)
            end
            lab.text = string.format("%s/%s",value,kv.v)
        end
    end
end
-----------------------------------------------------

function M:OnClickOpenBtn(go)
    if self.Status == false then
        if self.GetID == nil then
            UITip.Error("通过[五行秘境]获得开启天机印孔的材料")
        else
            GetWayFunc.ItemGetWay(self.GetID)
        end
        return
    end
    local info = self.Info
    if not info then
        UITip.Error("没有选中要开启的天机印")
        return 
    end

    SMSNetwork:ReqPlaceOpenTos(info.OpenTemp.id, SMSMgr.CurPage)
end

function M:UpdateConsum()
    self:UpdateInfoData(self.Info)
end

function M:SetActive(value)
    self.Root:SetActive(value)
end

function M:Reset()
    self.Info = nil
    self.GetID = nil
end

function M:DestroyPros(info)
    if not info then return end
    TableTool.ClearDic(info)
end

function M:Dispose()
end

return M