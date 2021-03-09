--region 
--
--此文件由[HS]创建生成

MoneyTreeNetwork = {Name = "MoneyTreeNetwork"}
local M = MoneyTreeNetwork

local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

local TipKey = "108"

function M:Init()
	self:AddProto()
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(26468, self.RespMoneyTreeToc, self)	
	Lsnr(26466, self.RespMoneyTreeIToc, self)	
	Lsnr(26470, self.RespMoneyTreeLogToc, self)	
end
--[[#############################################################]]--

--上线推送
function M:RespMoneyTreeToc(msg)
	MoneyTreeMgr:UpdateUseNum(msg.times)
	local logs = msg.log
	local len = #logs
	for i=1,len do
		local log = logs[i]
		MoneyTreeMgr:UpdateUserRecord(log.rate, log.money, true)
	end
	local oLogs = msg.other_log
	local oLen = #oLogs
	for i=1,oLen do
		local log = oLogs[i]
		MoneyTreeMgr:UpdatePlayerLuck(log.name, log.rate, log.money, true)
	end
end

--摇一摇返回
function M:RespMoneyTreeIToc(msg)
	if not CheckErr(msg.err_code) then
		return 
	end
	UITip.Error(string.format(StrTool.GetDes(TipKey), UIMisc.ToString(msg.money)))
	local log = msg.log
	MoneyTreeMgr:UpdateUseNum(MoneyTreeMgr.UseNum + 1)
	MoneyTreeMgr:UpdateUserRecord(msg.rate, msg.money)
	--MoneyTreeMgr.eGetMoney()
end

--全服日志
function M:RespMoneyTreeLogToc(msg)
	local log =  msg.other_log
	if log.type == 1 then
		MoneyTreeMgr:UpdatePlayerLuck(log.name, log.rate, log.money, true)
	elseif log.type == 2 then
		MoneyTreeMgr:UpdateUserRecord(log.rate, log.money, true)
	end
end
--[[#############################################################]]--
--摇一摇
function M:ReqMoneyTreeITos()
	local msg = ProtoPool.GetByID(26467)
	Send(msg)
end

--[[#############################################################]]--
function M:Clear()
	--self:RemoveProto()
end

return M