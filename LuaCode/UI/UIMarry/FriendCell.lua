FriendCell = Super:New{Name = "FriendCell"}

local M = FriendCell

function M:Init(go)
    local G = ComTool.Get
    local trans = go.transform

    self.go = go

    self.lblName = G(UILabel, trans, "Name")

    UITool.SetLsnrClick(trans, "BtnInvite", self.Name,  self.OnInvite, self)
end

function M:UpdateCell(data, temp)
    self.temp = temp
    self.data = data
    self.lblName.text = data.Name
end

function M:OnInvite()
    TeamMgr:ReqInviteTeam(self.data.ID)
    TeamMgr:ReqSetCopyTeam(self.temp.id, self.temp.lv, 1000)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:ActiveSelf()
    return self.go.activeSelf
end

function M:Dispose()
    self.data = nil
    self.temp = nil
    TableTool.ClearUserData(self)
end

return M