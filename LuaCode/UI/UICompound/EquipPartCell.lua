--[[
装备部位格子
]]
EquipPartCell=Super:New{Name="EquipPartCell"}
local My = EquipPartCell
My.eClick=Event()

function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    
    self.Cell=ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(trans)
    UITool.SetLsnrSelf(go,self.ClickPart,self,self.Name, false)
    self.lab=CG(UILabel,trans,"part",self.Name,false)
    self.red=TF(trans,"red")
end

function My:UpData(type_id)
    self.type_id=type_id
    self.Cell:UpData(type_id)
    local equip = EquipBaseTemp[tostring(type_id)]
    self:PartLab(equip.wearParts)
end

function My:ClickPart()
    My.eClick(self.type_id)
end

function My:PartLab(part)
    self.lab.text=UIMisc.WearParts(part)
end

function My:PartRed(isred)
    self.red:SetActive(isred)
end

function My:ShowState(isActive)
    self.go:SetActive(isActive)
end

function My:Dispose()
    if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) self.Cell=nil end
end