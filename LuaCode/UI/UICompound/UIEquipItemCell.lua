--[[
装备系统道具格子(增加了 + )
]]

UIEquipItemCell=Cell:New{Name="UIEquipItemCell"}
local My = UIEquipItemCell

function My:InitCustom()
    local TF=TransTool.FindChild
    self.add=TF(self.trans,"add")

    self:AddActive(true)
end

function My:AddActive(active)
    local add = self.add;
    if LuaTool.IsNull(add)==true then
        return;
    end
    add:SetActive(active)
end

function My:DisposeCus()
    self:AddActive(false)
end