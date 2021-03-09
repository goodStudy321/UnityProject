--[[
 	authors 	:Liu
 	date    	:2018-6-15 10:10:00
 	descrition 	:活动状态管理
--]]

ActivStateMgr = {Name = "ActivStateMgr"}

local My = ActivStateMgr

function My:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eUpActivState = Event()
end

--设置监听
function My:SetLnsr(func)
    func(20340,self.RespXsActivInfo, self)
    func(20342,self.RespUpXsActivState, self)
end

--响应限时活动信息
function My:RespXsActivInfo(msg)
    local list = msg.act_list
    for i,v in ipairs(list) do
        LivenessInfo:SetXsActivInfo(v.id, v.val, v.start_time, v.end_time, v.is_visible, v.start_date, v.end_date)
    end
    self.eUpActivState()
end

--响应更新显示活动状态
function My:RespUpXsActivState(msg)
    local act = msg.act
    LivenessInfo:SetXsActivInfo(act.id, act.val, act.start_time, act.end_time, act.is_visible, act.start_date, act.end_date)
    self.eUpActivState(act.id)
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
end

return My