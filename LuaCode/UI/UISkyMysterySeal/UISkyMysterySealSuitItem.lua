UISkyMysterySealSuitItem = Super:New{Name = "UISkyMysterySealSuitItem"}

local M = UISkyMysterySealSuitItem

function M:Init(go)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealSuitItem"

    self.Toggle = go:GetComponent(typeof(UIToggle))
    self.NameLab = C(UILabel, trans, "Name", name, false)
    self.ProGrid = C(UIGrid, trans, "Grid", name, false)
    self.Pros = {}
    for i=1,11 do
        local data = {}
        data.Root = T(trans, string.format("Grid/%s",i))
        data.Title = C(UILabel, trans, string.format("Grid/%s",i), name, false)
        data.Value = C(UILabel, trans, string.format("Grid/%s/Value",i), name, false)
        table.insert(self.Pros, data)
    end
    self.Height = 0
    self.Score = 0
    self.ActiveStatus = false
end

-----------------------------------------------------
function M:UpdateID(id)
    local temp = SMSSuitProTemp[tostring(id)]
    self:UpdateData(temp)
end

function M:UpdateData(temp)
    self:ResetPros()
    self.Temp = temp
    self.ActiveStatus = SMSMgr:GetSuitActiveStatusAllType(temp, temp.num)
    self:UpdateNameLab(temp.name, tostring(temp.num))
    self.Height = self:UpdatePros(temp)
    self.Score = PropTool.GetFight(temp, SMSMgr.ProKeys)
    self:SetActive(true)
end

function M:UpdateNameLab(name, str)
    local color = "907D63"
    if self.ActiveStatus == true then
        color = "00ff00"
    end
    self.NameLab.text = string.format("[%s]%s【%s】件激活[-]", color, name, str)
end

function M:UpdatePros(temp)
    local list = SMSMgr.ProKeys
    local num = 1
    local tColor = "907D63"
    local pColor = "907D63"
    if self.ActiveStatus == true then
        tColor = "F4DDBD"
        pColor = "00ff00"
    end
    for i=1,#list do
        local key = list[i]
        local pro = temp[key]
        if pro and pro ~= 0 then
            if num <= #self.Pros then
                self.Pros[num].Title.text = string.format("[%s]%s[-]", tColor, PropTool.GetName(key))
                self.Pros[num].Value.text = string.format("[%s]+%s[-]", pColor, math.floor(pro))
                self.Pros[num].Root:SetActive(true)
                num = num + 1
            end
        end 
    end
    self.ProGrid:Reposition()
    return num  * 22
end

function M:UpdatePos(pos)
    local root = self.Root 
    if not root then return end
    root.transform.localPosition = pos
end

function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    self.Score = 0
    self:SetActive(false)
    self.Temp = nil
    self.Height = 0
    self:UpdateNameLab("", "")
    self:ResetPros()
end

function M:ResetPros()
    local items = self.Pros
    if not items then return end
    local len = #items
    if len > 0 then
        for i=1,len do
            items[i].Title.text = ""
            items[i].Value.text = ""
            items[i].Root:SetActive(false)
        end
    end
end

function M:DestroyPros()
    local items = self.Pros
    if not items then return end
    local len = #items
    while len > 0 do
        local item = self.Pros[len]
        table.remove(self.Pros, len)
        item = nil
        len = #items
    end
end

function M:Dispose()
    self:DestroyPros()
end

return M