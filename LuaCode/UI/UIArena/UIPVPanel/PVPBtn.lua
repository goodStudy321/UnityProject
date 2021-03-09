PVPBtn = Super:New{Name = "PVPBtn"}
local My = PVPBtn

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.selectSp = TFC(trans,"hl",name)
    self.action = TFC(trans,"action",name)
    self.nameLab = CG(UILabel,trans,"name",name)
end

function My:BtnAct(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(name)
    self.nameLab.text = name
end

function My:SelectAct(ac)
    self.selectSp:SetActive(ac)
end

function My:SetRed(ac)
    self.action:SetActive(ac)
end

function My:Dispose()
    TableTool.ClearUserData(self)
end