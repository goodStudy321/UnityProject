ActToggle = BaseToggle:New{Name = "ActToggle"}

local M = ActToggle

function M:UpdateData(data)
    self.data = data
    self:UpdateName()
    self:UpdateRedPoint()
end

function M:UpdateName(state)
    local color = state and "[FFF0D4FF]" or "[E16158FF]"
    self.tgName.text = string.format("%s%s", color, self.data.name)
end

function M:UpdateRedPoint()
    local type = self.data.type
   local state = FestivalActMgr:GetRedPointState(type)
   self:SetRedPoint(state)
   self:UpNorAction(type)
end

--更新默认红点
function M:UpNorAction(type)
    local dic = FestivalActMgr.norActionDic
    local key = tostring(type)
    if dic[key] then
        self:SetRedPoint(true)
    end
end

function M:OnClick()
    self.eClick(self.data.type)
end

function M:SetHighlight(state)
    if not self:IsActive() then return end
    self.highlight:SetActive(state)
    self:UpdateName(state)
end

function M:DisposeCustom()
    self.data = nil
end

return M