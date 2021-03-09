ToggleCell = Super:New{Name = "ToggleName"}

local M = ToggleCell

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get

    self.goHL = TransTool.FindChild(trans, "highlight")
    self.name = G(UILabel, trans, "name")
    self.nameSec = G(UILabel, trans, "highlight/nameSec")
    UITool.SetLsnrSelf(go, self.Click, self, nil, false)
end

function M:UpdateCell(data)
    self.data = data
    self.name.text = data.name
    self.nameSec.text = data.name
end


function M:SetHandler(func, handler)
    self.func = func
    self.handler = handler
end

function M:SetHighlight(bool)
    self.goHL:SetActive(bool)
    self.name.gameObject:SetActive(not bool)
end

function M:Click()
    if self.data then
        self.func(self.handler, self.data.id)
    end
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.func = nil
    self.handler = nil
    self.data = nil
end

return M