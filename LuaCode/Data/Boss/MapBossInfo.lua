MapBossInfo = { Name = "MapBossInfo"}
local My = MapBossInfo;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--设置数据
function My:SetData(info)
    self.mapId = info.map_id;
    self.typeId = info.type_id;
    self.isAlive = info.is_alive;
    self.nxtRfTime = info.next_refresh_time;
    local id = tostring(self.typeId)
    local moinfo = MonsterTemp[id];
    if moinfo~=nil then
        self.lv=moinfo.level
    end
    self.what=SBCfg[tostring(self.typeId)].what;
    if self.what~=0 and self.what~=4 then
        self.lv=info.remain_num;
    end
end

--判断是否为神兽岛
function My:ChecSence( info )
    self.scenceInfo=SceneTemp[tostring(self.mapId)];
    local bossPlace = self.scenceInfo.mapchildtype; 
    return bossPlace;
end
