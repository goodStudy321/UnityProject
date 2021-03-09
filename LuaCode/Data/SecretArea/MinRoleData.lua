--[[
格子玩家的p结构   
]]
MinRoleData=Super:New{Name="MinRoleData"}
local My = MinRoleData

function My:Init(data)
    self.x=data.x
    self.y=data.y
    self.type_id=data.type_id
    self.role_id=data.role_id
    self.role_name=data.role_name
    self.category=data.category
    self.sex=data.sex
    self.family_id=data.family_id
    self.power=data.power
end

function My:Dispose()
    self.x=nil
    self.y=nil
    self.type_id=nil
    self.role_id=nil
    self.role_name=nil
    self.category=nil
    self.sex=nil
    self.family_id=nil
    self.power=nil
end
