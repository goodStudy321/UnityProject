--[[
	新的活动管理器
]]

NewActivInfo = Super:New{Name = "NewActivInfo"};
local My = NewActivInfo;
My.ActivInfo = {};

function My:Init()
	
end

--设置活动信息
function My:SetActivInfo(id, val , config_num, start_time, end_time)
    local tab = {id = id, val = val, configNum = config_num, startTime = start_time, endTime = end_time};
    local key = tostring(id);
    self.ActivInfo[key] = tab;
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    TableTool.ClearDic(self.ActivInfo);
end

return My;