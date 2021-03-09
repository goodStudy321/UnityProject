--[[
天机印部位格子
]]
NaturePartCell=EquipPartCell:New{Name="NaturePartCell"}
local My = NaturePartCell
My.eClick=Event()

function My:UpData(type_id)
    self.type_id=type_id
    self.Cell:UpData(type_id)
    local nature = NatureCompose[tostring(type_id)]
    self.lab.text=nature.name
end