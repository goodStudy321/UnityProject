--[[

]]
CollectSelect=Super:New{Name="CollectSelect"}
local My = CollectSelect
My.eClick=Event()

function My:Init(go)
    self.go=go
    local CG = ComTool.Get
    local TF=TransTool.FindChild 
    local trans = go.transform
    self.lab=CG(UILabel,trans,"Label",self.Name,false)
    self.Select=TF(trans,"Select")
    self.red=TF(trans,"red")

    UITool.SetLsnrSelf(go,self.OnClick,self,self.Name)
end

function My:OnClick()
    self:SelectActive(true)
    My.eClick(self.id)
end

function My:SelectActive(isActive)
    if self.Select then self.Select:SetActive(isActive) end
end

function My:ShowRed(isred)
    self.red:SetActive(isred)
end

function My:ShowLab(text)
    self.lab.text=text
end

function My:Dispose()
    Destroy(self.go)
    TableTool.ClearUserData(self)
end