AresCell = Cell:New{Name = "AresCell"}

local base = Cell
local M = AresCell

function M:Ctor()
    base.Ctor(self)
end

function M:UpdateData(data)
    self.data = data
    self:UpData(data.id, nil, self.data.state)
    self:UpdateGray()
    self:UpdateNum()
end

function M:UpRank()
    if self.data.state then
        self.rank.text=tostring(self.data.level).."阶"
        self.rank.gameObject:SetActive(true)
    else
        self.rank.gameObject:SetActive(false)
    end
end

function M:UpdateNum()
    if self.data.state then
        self.Lab.text = ""
    else
        local count =  AresMgr:GetMaterialCount(self.data.materialId)
        local color = count >= self.data.needCount and "[00FF00FF]" or "[F21919FF]"
        self.Lab.text = string.format("%s%s/%s", color, count, self.data.needCount)
    end
end

function M:UpdateGray()
    self:SetGray(not self.data.state, true)
end

function M:OnClick(go)
    if self.data then
        self.eClickCell(self.data)
    end
end

function M:DisposeCus()
    self.data = nil
    self:SetGray(false)
end

return M