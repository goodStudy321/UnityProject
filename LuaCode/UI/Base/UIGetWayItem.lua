UIGetWayItem = Super:New{Name = "UIGetWayItem"}

local M = UIGetWayItem

function M:Init(go)
    UITool.SetBtnSelf(go, self.OnClick, self)
    self.name = ComTool.Get(UILabel, go.transform, "Name")
end

function M:UpdateData(name, func, obj)
    self.name.text = name
    self.func = func
    self.obj = obj
end

function M:OnClick()
    if self.func and self.obj then
        self.func(self.obj, self.name.text)
    elseif self.func then
        self.func(self.name.text)
    end
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.func = nil
    self.obj = nil
end

return M