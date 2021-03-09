--[[
 	authors 	:Liu
 	date    	:2018-8-21 10:00:00
 	descrition 	:VIP投资管理
--]]

VIPInvestMgr = {Name = "VIPInvestMgr"}

local My = VIPInvestMgr

--判断当天奖励是否领取
My.isAward = false
--当前档次
My.awardLv = 0
--剩余天数
My.rDays = 0
--当前天数
My.nowDay = 0
--标记
My.isMark = false
--判断是否重置状态
My.isReset = false

function My:Init()
	self:SetLnsr(ProtoLsnr.Add)
	self.eGetAward = Event()
	self.eUpInfo = Event()
	self.eBuy = Event()
end

--设置监听
function My:SetLnsr(func)
	func(22570,self.RespVIPInvestInfo, self)
	func(22572,self.RespBuyVIPInvest, self)
	func(22574,self.RespGetAward, self)
end

--响应VIP投资信息
function My:RespVIPInvestInfo(msg)
	My.isAward = msg.is_reward
	My.awardLv = msg.reward_level
	My.rDays = msg.remain_days
	if My.isAward then
		My.rDays = My.rDays + 1
	end
	self:SetNowDay()
	self.eUpInfo()
	--更新红点
	self:CheckRedDot()
end

--请求购买VIP投资
function My:ReqBuyVIPInvest()
    local msg = ProtoPool.GetByID(22571)
	ProtoMgr.Send(msg)
end

--响应购买VIP投资
function My:RespBuyVIPInvest(msg)
	My.isAward = msg.is_reward
	My.awardLv = msg.reward_level
	My.rDays = msg.remain_days
	self:SetNowDay()
	My.isReset = true
	self.eBuy()
	self:CheckRedDot()
end

--请求获取奖励
function My:ReqGetAward()
    local msg = ProtoPool.GetByID(22573)
	ProtoMgr.Send(msg)
end

--响应获取奖励
function My:RespGetAward(msg)
	local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
	My.isAward = msg.is_reward
	My.rDays = msg.remain_days
	My.isMark = true
	self.eGetAward()
	self:CheckRedDot()
end

--设置当前天数
function My:SetNowDay()
	local len = 0
	for i,v in ipairs(VIPInvestCfg) do
		local lv = math.floor(v.id / 100)
		if lv == My.awardLv then
			len = len + 1
		end
	end
	if len == 0 then iTrace.Error("SJ", "VIP投资档次获取错误")
		return
	else
		My.nowDay = len - My.rDays + 1
	end
end

--检查红点
function My:CheckRedDot()
	local dic = VIPMgr.stateDic
	if My.isAward then
		VIPMgr.UpAction(7, false)
	else
		VIPMgr.UpAction(7, true)
	end
end

--清理缓存
function My:Clear()
	My.isAward = false
	My.awardLv = 0
	My.rDays = 0
	My.nowDay = 0
	My.isMark = false
	My.isReset = false
end
    
--释放资源
function My:Dispose()
	self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
end

return My