DemonCurOccupyCell = DemonOccupyCell:New{Name = "DemonCurOccupyCell"}

local M = DemonCurOccupyCell
local base = DemonOccupyCell

function M:Init(go)
    base:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    self.mLife = G(UILabel, trans, "Life")
end

function M:UpdateData(data)
    if not data then return end
    base:UpdateData(data)
    self:UpdateLife()
end

function M:UpdateLife()
    local sec = self.data.CurOccupyTime
    local list = GlobalTemp["140"].Value1
    local buffId = 0
    for i=1,#list do
        if list[i].id <= sec then
            buffId = list[i].value
        end
    end
    if buffId ~= 0 then
        local buff = BuffTemp[tostring(buffId)]
        local data = buff.valueList[1]   
        local prop = PropName[data.k]
        local num = data.v
        if prop.show == 1 then
            self.mLife.text = string.format("生命增加:%s%%", num*0.01)
        else
            self.mLife.text = string.format("生命增加:%s", num)
        end
    else       
        self.mLife.text = ""
    end
end


return M