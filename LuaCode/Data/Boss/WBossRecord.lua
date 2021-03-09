require("Data/Boss/WBRcdInfo")
WBossRecord = { Name = "WBossRecord" }
local My = WBossRecord;
My.eUpBRcd = Event();
My.WBRcdInfos={}
My.smRcdInfos={}

function My:Init()
    self:AddEventLsnr();
end

function My:AddEventLsnr()
    NetBoss.eUpBRcd:Add(self.UpBRcd,self);
    NetBoss.eUpnormalBRcd:Add(self.UpsmaRcd,self);
end

--刷新纪录
function My:UpBRcd(logList)
    if logList == nil then
        return;
    end
    local len = #logList;
    if len == 0 then
        return;
    end
    for i = 1,len do
        local logInfo = WBRcdInfo:New();
        local info = logList[i];
        logInfo:SetData(info.role_id,info.role_name,info.map_id,info.monster_type_id,info.item_type_id,info.time);
        self.WBRcdInfos[i] = logInfo;
    end
    self.eUpBRcd(1);
end
--刷新纪录
function My:UpsmaRcd(smaList)
    if smaList == nil then
        return;
    end
    local len = #smaList;
    if len == 0 then
        return;
    end
    for i = 1,len do
        local logInfo = WBRcdInfo:New();
        local info = smaList[i];
        logInfo:SetData(info.role_id,info.role_name,info.map_id,info.monster_type_id,info.item_type_id,info.time);
        self.smRcdInfos[i] = logInfo;
    end
    self.eUpBRcd(2);
end

function My:Clear()
    soonTool.ClearList(self.WBRcdInfos)
    soonTool.ClearList(self.smRcdInfos)
end

function My:Dispose()
    self:Clear();
end

return My