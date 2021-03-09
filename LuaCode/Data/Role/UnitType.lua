UnitType = {Name = "UnitType"}
local My = UnitType;
     
--人物
My.Role = 1 
-- 怪物
My.Monster = 2
-- 采集物
My.Collection = 3
-- PNC
My.NPC = 4
-- 召唤体
My.Summon = 6
-- 虚拟体
My.VirtualSummon = 7
-- 神兵
My.Artifact = 8 
-- 法宝
My.MagicWeapon = 9 
-- 翅膀
My.Wing = 10 
-- 坐骑
My.Mount = 11 
-- 宠物
My.Pet = 12 
-- 掉落物
My.DropItem = 13 
-- boss
My.Boss = 20  

function My:Init()

end

--获取单位类型
function My.GetUnitType(typeId)
    if typeId == nil then
        return 0;
    end
    if  typeId > 10000 and  typeId <= 99999 then
        return My.Role;
    elseif  typeId > 200000 and  typeId <= 299999 then
        return My.Monster;
    elseif  typeId >= 3070000 and  typeId <= 3079999 then
        return My.Summon;
    elseif  typeId > 3010000 and  typeId <= 3069999 then
        local type = ( typeId / 10000) % 300;
        if type == PendantType.Artifact then
            return My.Artifact;
        elseif type == PendantType.FashionableDress then
            return My.Role;
        elseif type == PendantType.MagicWeapon then
            return My.MagicWeapon;
        elseif type == PendantType.Mount then
            return My.Mount;
        elseif type == PendantType.Pet then
            return My.Pet;
        elseif type == PendantType.Wing then
            return My.Wing;
        end
    elseif unitTypeId >= 30200000 and unitTypeId <= 30299999 then
        local type = ( typeId / 100000) % 300;
        if type == PendantType.MagicWeapon then
            return My.MagicWeapon;
        end
    elseif  typeId > 100000 and  typeId <= 199999 then

    end
end

function My:Clear()

end

return My;