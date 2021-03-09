PracExpIt = Super:New{Name = "PracExpIt"}
local My = PracExpIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
	local US = UITool.SetLsnrSelf
	self.expSp = trans:GetComponent(typeof(UISprite))
end

function My:SetActive(ac)
    self.expSp.enabled = ac
end

function My:Dispose()
    TableTool.ClearUserData(self)
end

return My