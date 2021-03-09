TitleCell = Super:New{Name = "TitleCell"}

local M = TitleCell

function M:Init(go)
    local FG = TransTool.FindChild
    local trans = go.transform

    self.go = go
    UITool.SetLsnrSelf(go, self.Click, self, nil, false)
    self.goHL = FG(trans, "highlight")
    self.goSP_1 = FG(trans, "sp_1")
    self.goSP_2 = FG(trans, "sp_2")
    self.goSP_3 = FG(trans, "sp_3")
    self.lblName = ComTool.Get(UILabel, trans, "name")
end

function M:SetHandler(func, handler)
    self.func = func
    self.handler = handler
end

function M:UpdateCell(data)
    self.data = data 
    self.lblName.text = data.cfg.name

    local function set(b1, b2, b3)
        self.goSP_1:SetActive(b1)
        self.goSP_2:SetActive(b2)
        self.goSP_3:SetActive(b3)
    end
    
    if data.isUse == 1 then
        set(true, false, false)
    elseif data.have ~= -1 then
        set(false, true, false)
    else
        set(false, false, true)
    end
end

function M:Click()
    if not self.data then return end
    self.func(self.handler, self.data.cfg.id)  
end

function M:SetHighlight(bool)
    self.goHL:SetActive(bool or false)     
end

function M:SetActive(bool)
    self.go:SetActive(bool or false)
end

function M:ActiveSelf()
    return self.go.activeSelf
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.func = nil
    self.handler = nil
    self.data = nil
end

return M