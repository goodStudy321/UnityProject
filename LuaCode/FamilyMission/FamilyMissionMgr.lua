--[[
 	authors 	:Liu
 	date    	:2019-6-15 17:00:00
 	descrition 	:道庭任务管理类
--]]

FamilyMissionMgr = {Name = "FamilyMissionMgr"}

local My = FamilyMissionMgr

local Info = require("FamilyMission/FamilyMissionInfo")

function My:Init()
    Info:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eUpMenu = Event()
    self.eUpMission = Event()
    self.eUpMissionInfo = Event()
    self.eUpHelpMenu = Event()
    self.eHelp = Event()
    self.eHelpBtn = Event()
    self.eRefresh = Event()
    self.eNorRefresh = Event()
    -- self.eHelpError = Event()
    -- self.eClickSpeed = Event()
end

--设置监听
function My:SetLnsr(func)
    func(26202,self.RespInfo, self)
    func(26204,self.RespMissionHelp, self)
    func(26206,self.RespMissionState, self)
    func(26208,self.RespHelpSelf, self)
    func(26210,self.RespHelp, self)
    func(26220,self.RespUpMission, self)
    func(26222,self.RespUpMissionRefresh, self)
end

--请求道庭任务信息
function My:ReqInfo()
    local msg = ProtoPool.GetByID(26201)
    ProtoMgr.Send(msg)
end

--响应道庭任务信息
function My:RespInfo(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    ListTool.Clear(Info.missionList)
    Info.isRefresh = msg.renovate
    for i,v in ipairs(msg.family_mission) do
        Info:SetMissionData(v.mission_id, v.type, v.expedite, v.start_time, v.stop_time)
    end
    self.eUpMenu()
    self:UpAction()
end

--请求道庭任务状态(0:接任务,1:向道庭成员求助,2:放弃,3:领取奖励)
function My:ReqMissionState(id, state)
    local msg = ProtoPool.GetByID(26205)
    msg.mission_id = id
    msg.type = state
    ProtoMgr.Send(msg)
end

--响应道庭任务状态
function My:RespMissionState(msg)
    -- iTrace.Error("msg2 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		UITip.Error(ErrorCodeMgr.GetError(err))
        return
    end
    local type = msg.type
    local id = msg.mission_id
    if type == 3 then Info:RemoveMission(id) end
    self.eUpMission(id, type)
end

--响应更新道庭任务
function My:RespUpMission(msg)
    -- iTrace.Error("msg3 = "..tostring(msg))
    local v = msg.family_mission
    local missionId = v.mission_id
    local state = v.type
    local count = v.expedite
    local startTime = v.start_time
    local endTime = v.stop_time
    Info:SetMissionData(missionId, state, count, startTime, endTime)
    self.eUpMissionInfo(missionId, state, count, startTime, endTime)
    self:UpAction()
end

--请求道庭任务刷新（0:元宝刷新,1:极品刷新）
function My:ReqMissionRefresh(type)
    local msg = ProtoPool.GetByID(26221)
    msg.type = type
    ProtoMgr.Send(msg)
end

--响应道庭任务刷新
function My:RespUpMissionRefresh(msg)
    -- iTrace.Error("msg4 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		UITip.Error(ErrorCodeMgr.GetError(err))
        return
    end
    local type = msg.type
    local id = msg.mission_id
    if type == 1 then
        Info:RemoveMission(id)
        Info.isRefresh = false
        self.eRefresh(id)
        self:UpAction()
    else
        self.eNorRefresh()
    end
end

--请求道庭任务求助信息
function My:ReqMissionHelp()
    local msg = ProtoPool.GetByID(26203)
    ProtoMgr.Send(msg)
end

--响应道庭任务求助信息
function My:RespMissionHelp(msg)
    -- iTrace.Error("msg5 = "..tostring(msg))
    ListTool.Clear(Info.helpList)
    Info.inspire = msg.inspire
    for i,v in ipairs(msg.mission_ask) do
        local id = 0
        local count = 0
        for i1, v1 in ipairs(v.family_mission) do
            id = v1.mission_id
            count = v1.expedite
        end
        Info:SetHelpList(v.role_id, v.role_name, v.sex, v.vip_level, count, id)
    end
    self.eUpHelpMenu()
    self:UpHelpBtn()
    self:UpAction()
end

--响应道庭成员向自己求助
function My:RespHelpSelf(msg)
    -- iTrace.Error("msg6 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		UITip.Error(ErrorCodeMgr.GetError(err))
        return
    end
    if User.MapData.UIDStr ~= tostring(msg.member_id) then
        self.eHelpBtn(true)
        -- if not Info:IsMaxCount() then self.eHelpBtn(true) end
        -- self.eClickSpeed()
    end
end

--请求加速
function My:ReqHelp(memberId, missionId)
    local msg = ProtoPool.GetByID(26209)
    msg.member_id = memberId
    msg.mission_id = missionId
    ProtoMgr.Send(msg)
end

--响应加速
function My:RespHelp(msg)
    -- iTrace.Error("msg7 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
        UITip.Error(ErrorCodeMgr.GetError(err))
        -- self.eHelpError()
        self:ReqMissionHelp()
        return
    end
    local id = msg.member_id
    -- local count = msg.inspire
    Info.inspire = msg.inspire
    local missionId = msg.mission_id
    if id == 0 or missionId == 0 then
        self.eHelp(0)
        return
    end
    Info:UpHelpList(id, missionId)
    self.eHelp(id)
    self:UpAction()
end

--更新主界面的求助按钮
function My:UpHelpBtn()
    local isShow = self:IsShowHelp()
    self.eHelpBtn(isShow)
end

--主界面是否显示求助
function My:IsShowHelp()
    -- if Info:IsMaxCount() then return false end
    -- local isShow = false
    -- for i,v in ipairs(Info.helpList) do
    --     local maxCount = Info:GetMaxSpeed(v.vip)
    --     if v.count < maxCount then
    --         isShow = true
    --     end
    -- end
    -- return isShow
    return #Info.helpList > 0
end

--更新红点
function My:UpAction()
    local state = self:IsShowAction()
    FamilyMgr.eRed(state, 1, 2)
end

--是否能领取奖励
function My:IsShowAction()
    local state1 = false
    local state2 = Info.isRefresh
    for i,v in ipairs(Info.missionList) do
        if v.state == 3 or v.state == 0 then
            state1 = true
        end
    end
    return state1 or state2
end

--清理缓存
function My:Clear()
    Info:Clear()
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
end

return My