--region Mission.lua
--Cell基类 只有Icon
--此文件由[HS]创建生成

MissionNetwork = {Name = "MissionNetwork"}
local M = MissionNetwork


local cMgr = nil
local mMgr = nil
local Send = nil
local CheckErr = nil

function M:Init()
	cMgr = ChapterMgr
	mMgr = MissionMgr
	Send = ProtoMgr.Send
	CheckErr = ProtoMgr.CheckErr
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(23002, self.RespMissionInfoToc, self)	
	Lsnr(23004, self.RespAcceptMissionToc, self)	
	Lsnr(23006, self.RespCompleteMissionToc, self)	
	Lsnr(23008, self.RespCancelMissionToc, self)	
	Lsnr(23010, self.RespUpdateMissionToc, self)	
	Lsnr(23012, self.RespUpdateMissionTargetToc, self)	
	Lsnr(23014, self.RespTriggerMissionTargetToc, self)	
	Lsnr(23022, self.RespMissionOneKeyToc, self)	
end
--[[#############################################################]]--
--登入刷新任务
function M:RespMissionInfoToc(msg)
	mMgr:CleanAllMission()
	local mgr = MissionMgr
	local list = msg.missions
	for i=1,#list do
		local info = list[i]
		mMgr:EnterGetMission(info)
		User:SetMissionID(info.mission_id)
		cMgr:UpdateMission(info.mission_id, info.status, info.succ_times, true)
	end
	mMgr:UpdateMissionEnd()
end

--接受任务请求返回
function M:RespAcceptMissionToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.mission_id
	mMgr:UpdateMissionStatus(id, MStatus.EXECUTE, true)
	Hangup:MissionUpdate(id, MStatus.EXECUTE)
	mMgr:UpdateMissionEnd()
end

--完成任务请求返回
function M:RespCompleteMissionToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	local id = msg.mission_id
	cMgr:MissionCancel(id, true)
	EventMgr.Trigger("MssnEnd", id)
	NPCMgr.instance:SetNPC(id)
	mMgr:CompleteMission(id, true, true)
	mMgr:UpdateMissionEnd()
end

--取消任务返回
function M:RespCancelMissionToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	cMgr:MissionCancel(id, false)
	mMgr:CompleteMission(id)
	mMgr:UpdateMissionEnd()
end

--更新任务
function M:RespUpdateMissionToc(msg)
	local dels = msg.del
	for i=1,#dels do
		mMgr:CompleteMission(dels[i])
		cMgr:MissionCancel(dels[i], true)
	end
	local updates = msg.update
	for i=1,#updates do
		local info = updates[i]
		mMgr:EnterGetMission(info, true)
		User:SetMissionID(info.mission_id)
		Hangup:MissionUpdate(info.mission_id, info.status)
		cMgr:UpdateMission(info.mission_id, info.status, info.succ_times, nil)
	end
	mMgr:UpdateMissionEnd()
end

--更新任务目标
function M:RespUpdateMissionTargetToc(msg)
	local id = msg.mission_id
	local listens = msg.listens
	mMgr:ChangeTargets(id, listens, true)
	mMgr:UpdateMissionEnd()
end

--触发任务返回
function M:RespTriggerMissionTargetToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
end

--一键帮派任务返回
function M:RespMissionOneKeyToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
end
--[[#############################################################]]--
--接受任务请求
function M:ReqAcceptMission(id)
	local msg = ProtoPool.GetByID(23003)
	msg.mission_id = id
	Send(msg)
end

--完成任务请求
function M:ReqCompleteMission(id)
	local msg = ProtoPool.GetByID(23005)
	msg.mission_id = id
	Send(msg)
end

--取消任务请求
function M:ReqCancelMission(id)
	local msg = ProtoPool.GetByID(23007)
	msg.mission_id = id
	Send(msg)
end

--触发任务
function M:ReqTriggerMission(t, v)
	local msg = ProtoPool.GetByID(23013)
	msg.type = t
	msg.val = v
	Send(msg)
end

--一键帮派
function M:ReqMissionOnKey(t)
	local msg = ProtoPool.GetByID(23021)
	msg.type = t
	Send(msg)
end

--[[#############################################################]]--
function M:Clear()
	self:RemoveProto()
end

return M