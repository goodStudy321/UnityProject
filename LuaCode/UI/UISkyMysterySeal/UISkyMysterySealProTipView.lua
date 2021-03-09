UISkyMysterySealProTipView = {}

local M = UISkyMysterySealProTipView

function M:New(go)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealProTipView"
    self.Mask = T(trans, "Mask")
    self.BasePros = {}
    self.StrengthPros = {}
    self:InitPros(self.BasePros, T(trans, "BasePro"), name)
    self:InitPros(self.StrengthPros, T(trans, "StrengthPro"), name)
    UITool.SetLsnrSelf(self.Mask, self.Reset, self, nil, false)
	return self
end

function M:InitPros(info, go, name)
    local trans = go.transform
    local C = ComTool.Get
    local T = TransTool.FindChild
    info.Root = go
    --info.SV = C(UIScrollView, trans, "ScrollView")
    --info.Panel = C(UIPanel, trans, "ScrollView")
    --info.PanelPos = info.Panel.transform.localPosition
    info.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
    info.Pros = {}
    for i=1,11 do
        local pro = {}
        pro.Root = T(trans, string.format("ScrollView/Grid/Pro%s", i))
        pro.Title = C(UILabel, trans,string.format("ScrollView/Grid/Pro%s", i), name, false)
        pro.Value = C(UILabel, trans,string.format("ScrollView/Grid/Pro%s/Label", i), name, false)
        table.insert(info.Pros,  pro) 
    end
end

-----------------------------------------------------
function M:UpdateData()
    --local show = false
    self:Reset()
    local all = SMSMgr.Infos
    local basePros = {}
    local strengthPros = {}
    for i,infos in ipairs(all) do
        local len = #infos
        for i=0, len do
            local info = infos[i]
            if info and info.Pro and info.Pro.Item then
                local temp = SMSProTemp[tostring(info.Pro.Item.type_id)]
                if temp then
                    self:AddBasePro(basePros, temp)
                    lv = info.Pro.StrengthLv
                    if info.Pro.StrengthLv > temp.limit then
                        lv = tostring(temp.limit)
                    end 
                    self:AddStrengthPro(basePros, info.Pro.Index, lv)
                end
                --show = true
            end
        end
    end
    local suitInfos = SMSMgr.SuitActiveInfos
    for i,v in ipairs(suitInfos) do
        for index,id in ipairs(v) do
            local temp = SMSSuitProTemp[tostring(id)]
            if temp then
                self:AddBasePro(basePros, temp)
            end
        end
    end
    self:UpdatePros(self.BasePros, basePros)
    --self:UpdatePros(self.StrengthPros, strengthPros)
    --self:SetActive(show)
end

function M:AddBasePro(pros, temp)
    local list = SMSMgr.ProKeys
    for i=1,#list do
        local key = list[i]
        local pro = temp[key]
        if pro and pro ~= 0 then
            if pros[key] == nil then
                pros[key] = 0
            end
            pros[key] = pros[key] + pro
        end 
    end
end

function M:AddStrengthPro(pros, index, lv)
    local id = 10000+index*1000+lv
    local temp = SMSStrengthTemp[tostring(id)]
    if temp then
        local list = SMSMgr.ProKeys
        for i=1,#list do
            local key = list[i]
            local pro = temp[key]
            if pro and pro ~= 0 then
                if pros[key] == nil then
                    pros[key] = 0
                end
                pros[key] = pros[key] + pro
            end 
        end
    end
end

function M:UpdatePros(uis, pros)
    local num = 1
    local len = LuaTool.Length(pros)
    --uis.Root:SetActive(len > 0)
    if len == 0 then return end
    local list = SMSMgr.ProKeys
    for i=1,#list do
        local key = list[i]
        local pro = pros[key]
        if pro ~= nil then
            if num <= #uis.Pros then
                uis.Pros[num].Title.text = PropTool.GetName(key)
                uis.Pros[num].Value.text = tostring(pro)
                uis.Pros[num].Root:SetActive(true)
                num = num + 1
            end
        end
    end
    --uis.Panel.transform.localPosition = uis.PanelPos 
    --uis.Panel.clipOffset = Vector3.zero
    uis.Grid:Reposition()
    --uis.SV.isDrag = num >=7
end
-----------------------------------------------------

function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    self:ResetPros(self.BasePros)
    self:ResetPros(self.StrengthPros)          
    --self:SetActive(false)                            
end

function M:ResetPros(info)
    if not info then return end
    local len = #info.Pros
    if len > 0 then
        for i=1,len do
            --info.SV.isDrag = false
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
    self:DestroyPros(self.BasePros)
    self:DestroyPros(self.StrengthPros)
end