--[[
部件拆解
]]
ResolveTip=Super:New{Name="ResolveTip"}
local My = ResolveTip

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = go.transform
    local U = UITool.SetLsnrClick
    
    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    U(trans,"noBtn",self.Name,self.Close,self)
    U(trans,"mask",self.Name,self.Close,self)
    U(trans,"yesBtn",self.Name,self.OnYes,self)
end

function My:UpData(partId)
    self.partId=partId
    local data=SuitStarData[partId]
    local list=data.needList
    local type_id=list[1]
    local num = list[2]
    self.cell=ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.grid.transform)
    self.cell:UpData(type_id,num,false)
end

function My:OnYes()
    SuitMgr.ReqResolve(tonumber(self.partId))
    self:Close()
end

function My:Open()
    self.go:SetActive(true)
end

function My:Clean()
    if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
end

function My:Close()
    self:Clean()
    self.go:SetActive(false)
end

function My:Dispose()
    self:Clean()
end