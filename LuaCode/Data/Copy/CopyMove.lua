CopyMove = { Name = "CopyMove"}
local My = CopyMove;

--设置自动挂机移动位置
function My:SetMovePos(mapid, progress)
    local cpId = tostring(mapid);
    local cpInfo = CopyTemp[cpId];
    if cpInfo == nil then
        return;
    end

    local info = nil;
    if cpInfo.type == CopyType.Equip then
        local id = mapid * 100 + progress;
        id = tostring(id);
        info = CopyEquipTemp[id];
    elseif cpInfo.type == CopyType.Tower then
        local id = tostring(mapid);
        info = CopyTowerTemp[id];
    elseif cpInfo.type == CopyType.XM then
        local id = tostring(mapid);
        info = CopyEvil[id];
    elseif cpInfo.type == CopyType.Hjk then
        local id = tostring(mapid);
        info = CopyHjk[id];
    elseif cpInfo.type == CopyType.PBoss then
        local id = tostring(mapid);
        info = CopyPBoss[id];
    elseif cpInfo.type == CopyType.Loves then
        local id = mapid * 100 + progress;
        id = tostring(id);
        info = LoveCopyCfg[id];
    elseif cpInfo.type == CopyType.ZLT then
        local id = mapid * 100 + progress;
        id = tostring(id);
        info = CopyZLTTemp[id];
    elseif cpInfo.type == CopyType.ZHTower then
        local id = mapid * 100 + progress;
        id = tostring(id);
        info = CopyZHTowerTemp[id];
    elseif cpInfo.type == CopyType.TreasureTeam then
        local id = mapid * 100 + progress;
        id = tostring(id);
        info = CopyTreasureTemp[id];
    elseif cpInfo.type == CopyType.TreasureBoss then
        info = TreasureBaseCfg["201"]
    elseif cpInfo.type == CopyType.Fever then
        info = CopyFeverTemp[cpId]
    end
    if info == nil then
        return;
    end
    self:SetDesPos(info.pos);
end

--设置目标位置
function My:SetDesPos(posInfo)
    if posInfo == nil then
        return;
    end
    local len = #posInfo;
    if len ~= 2 then
        return;
    end
    local startX = posInfo[1].x;
    local startZ = posInfo[1].y;
    local endX = posInfo[2].x;
    local endZ = posInfo[2].y;
    User:SetCopyDesPos(startX,startZ,endX,endZ);
end