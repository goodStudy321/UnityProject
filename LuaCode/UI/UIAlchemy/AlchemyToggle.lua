AlchemyToggle = BaseToggle:New{Name = "AlchemyToggle"}

local M = AlchemyToggle

function M:SetName(value)
    self.toggleName = value
    self.tgName.text = string.format("%s%s", "[E16158FF]", value)
end

function M:UpdateName(state)
    local color = state and "[FFF0D4FF]" or "[E16158FF]"
    self.tgName.text = string.format("%s%s", color, self.toggleName)
end

function M:SetHighlight(state)
    if not self:IsActive() then return end
    self.highlight:SetActive(state)
    self:UpdateName(state)
end

function M:DisposeCustom()
    self.toggleName = nil
end

return M