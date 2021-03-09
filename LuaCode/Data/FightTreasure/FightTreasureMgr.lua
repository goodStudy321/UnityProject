--region FightTreasureMgr.lua
--
--此文件由[HS]创建生成

FightTreasureMgr = {Name = "FightTreasureMgr"}
local M = FightTreasureMgr

local cMgr = ChapterMgr
local mMgr = MissionMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
M.eChangeStatus = Event()

M.OpenLvTemp = GlobalTemp["129"]

function M:Init()
	self.ReceiveStatus = true
	self:AddProto()
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(26110, self.RespUpdateStatusToc, self)	
	Lsnr(26112, self.RespReceiveRewardToc, self)	
end
--[[#############################################################]]--
--登入更新状态
function M:RespUpdateStatusToc(msg)
	self.ReceiveStatus = msg.can_get
	self.eChangeStatus()
end

--领取奖励返回
function M:RespReceiveRewardToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	self.ReceiveStatus = false
	self.eChangeStatus()
end

--[[#############################################################]]--
--领取奖励请求
function M:ReqReceiveRewardTos()
	local msg = ProtoPool.GetByID(26111)
	Send(msg)
end

--[[#############################################################]]--

function M:GetOpenLv()
	local temp = self.OpenLvTemp
	if temp then
		return temp.Value3
	end
	return 1
end

function M:IsShowIcon()
	if User.MapData.Level >= self:GetOpenLv() then
		return true
	end
	return false
end

function M:Clear()
	self.ReceiveStatus = true
end

function M:Dispose()
	self:RemoveProto()
end
return M