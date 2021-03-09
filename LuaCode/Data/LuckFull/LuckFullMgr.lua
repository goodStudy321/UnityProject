--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-12 01:04:47
--=========================================================================

LuckFullMgr = Super:New{ Name = "LuckFullMgr" }

local My = LuckFullMgr
local GetErr = ErrorCodeMgr.GetError
----BEG PUBLIC

function My:Init()

	--系统ID
	self.sysID = 2005
	self.actInfo = NewActivMgr:GetActivInfo(sysID)
	self:Reset()
	self:SetProp()
	self:AddLsnr()
end

--存入活动信息
function My:SaveActivInfo(activInfo)
	self.actInfo = activInfo;
end

--判断系统是否已开启
--return:true(已开启)
function My:IsOpen()
	local info = self.actInfo
	local state = info and info.val or 2
	return (state == 1)
end

--获取结束时间
function My:GetEndTime()
	local info = self.actInfo
	local tm = info and info.endTime or 0
	return tm
end


----END PUBLIC
function My:Reset()
	--配置ID
	self.id = 0
	--幸运值
	self.luck = 0
	--true:自动刷新中
	self.isAuto = false
end


function My:Clear()
	self:Reset()
	UIMgr.Close("UILuckFull")

end

function My:SetProp()
	--全局配置
	local cfg = GlobalTemp["181"]
	local v2 = cfg.Value2

	--消耗货币类型
	self.conGoldTy = v2[1]
	--每次消耗元宝数量
	self.oneConGold = v2[2]
	--每次递增幸运值
	self.addLuck = v2[3]
	--幸运值上限
	self.luckMax = v2[4]
end

function My:GetConGoldTy()
	do return self.conGoldTy end
end

function My:GetOneConGold()
	do return self.oneConGold end
end

function My:GetAddLuck()
	do return self.addLuck end
end

function My:GetLuckMax()
	do return self.luckMax end
end


--设置珍惜道具ID和幸运值
--id(number)配置ID
--luck(number)幸运值
function My:SetLuckID(id, luck)
	
	self.id = id
	self.luck = luck
	--iTrace.eError("22222222   --------id:",self.id)
end

function My:AddLsnr()
	--系统状态更新事件,参数self.actInfo
	self.eSysState = Event()
	--响应鉴宝信息
	self.eInfo = Event()
	--响应开始鉴宝事件
	self.eBeg = Event()
	--响应停止事件
	self.eStop = Event()
	
 	local Add = ProtoLsnr.Add
    Add(27102, self.RespInfo, self)
    Add(27104, self.RespBeg, self)
    Add(27106, self.RespStop, self)

	ActivStateMgr.eUpActivState:Add(self.SysUpdate, self)

end

--请求鉴宝信息
function My:ReqInfo()
	local msg = ProtoPool.GetByID(27101)
	--iTrace.eError("33333333333333:")
    ProtoMgr.Send(msg)
end

--响应鉴宝信息
function My:RespInfo(msg)
	local err = msg.err_code
	local idChanged = false
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
    else
		idChanged = (msg.id ~= self.id)
		--iTrace.eError("1111111   --------id:",msg.id)
		self:SetLuckID(msg.id, msg.luck)
    end
    self.eInfo(msg, idChanged)
end

--ty(nnumber):0:鉴宝一次,1:自动
function My:ReqBeg(ty)
	local msg = ProtoPool.GetByID(27103)
	msg.type = ty
    ProtoMgr.Send(msg)
end

--响应开始鉴宝
function My:RespBeg(msg)
	local err = msg.err_code
	local idChanged = false
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
        self.isAuto = true
        if msg.type == 1 then
    		self:ReqStop()
        end
    else
    	self.isAuto = (msg.type == 1)
    	idChanged = (msg.id ~= self.id)
        self:SetLuckID(msg.id, msg.luck)
    end
    self.eBeg(msg, idChanged)
end

--请求停止自动
function My:ReqStop()
	local msg = ProtoPool.GetByID(27105)
    ProtoMgr.Send(msg)
end

--响应停止自动
function My:RespStop(msg)
	local err = msg.err_code
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
    end
    self.isAuto = false
    self.eStop(msg)
end

--系统状态更新
function My:SysUpdate()
	local sysID = self.sysID
    local need = nil
    if id == nil or id == sysID then
        self.actInfo = NewActivMgr:GetActivInfo(sysID)
        self.eSysState(self.actInfo)
    end
end




return My