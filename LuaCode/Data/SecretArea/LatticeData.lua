--[[
格子坐标结构
]]
LatticeData=Super:New{Name="LatticeData"}
local My = LatticeData

function My:Init(data)
    self.x=data.x
    self.y=data.y
    self.type_id=data.type_id
    self.surplus_num=data.surplus_num --剩余次数
    self.renovate_time=data.renovate_time --重置时间

    if not self.mining_role then self.mining_role={} end
    local mining_role = data.mining_role
    if mining_role then 
        ListTool.Clear(self.mining_role)
        for i,v in ipairs(mining_role) do
            self.mining_role[i]=tostring(v) --格子里的玩家
        end
    end
end

function My:Dispose()
    self.x=nil
    self.y=nil
    self.type_id=nil
    self.surplus_num=nil
    self.renovate_time=nil
    ListTool.Clear(self.mining_role)
end