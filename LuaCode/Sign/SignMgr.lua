--[[
 	authors 	:Liu
 	date    	:2018-5-15 18:28:08
 	descrition 	:签到管理
--]]

SignMgr = {Name = "SignMgr"}

local My = SignMgr

local Info = require("Sign/SignInfo")

My.isOpen = false

function My:Init()
	Info:Init()
	self:AddLnsr()
	self.eSign = Event()
	self.eSignAward = Event()
end

--添加监听
function My:AddLnsr()
	self:SetLnsr(ProtoLsnr.Add)
end

--移除监听
function My:RemoveLsnr()
	self:SetLnsr(ProtoLsnr.Remove)
end

--设置监听
function My:SetLnsr(func)
	func(20350,self.RespSignInfo, self)
	func(20352,self.RespSign, self)
	func(20356,self.RespGetSignAward, self)
end

--响应签到信息
function My:RespSignInfo(msg)
	Info:ClearList()
	Info.isSign = msg.is_sign
	Info.SignCount = msg.sign_times
	for i,v in ipairs(msg.times_reward_list) do
		table.insert(Info.SignAwardList, v)
	end
	My.isOpen = true
	self:UpRedDot()

	local ui = UIMgr.Get(UILvAward.Name)
	if ui then
		ui:Close()
	end
end

--请求签到
function My:ReqSign()
	local msg = ProtoPool.GetByID(20351)
	ProtoMgr.Send(msg)
end

--响应签到
function My:RespSign(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	Info.isSign = msg.is_sign
	Info.SignCount = msg.sign_times
	self.eSign()
	self:UpRedDot()
end

--请求领取签到次数奖励
function My:ReqGetSignAward(count)
	local msg = ProtoPool.GetByID(20355)
	msg.times = count
	ProtoMgr.Send(msg)
end

--响应领取签到次数奖励
function My:RespGetSignAward(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	table.insert(Info.SignAwardList, msg.times)
	self.eSignAward()
	self:UpRedDot()
end

--更新红点
function My:UpRedDot()
	local isShow = self:IsShowRedDot()
	LvAwardMgr:UpAction(3, isShow)
end

--判断是否显示红点
function My:IsShowRedDot()
	local isGet = self:IsGetAward()
	if isGet or not Info.isSign then
		return true
	end
	return false
end

--判断是否能领取签到次数奖励
function My:IsGetAward()
	local list = {}
	local count = Info:GetSignCount()
	for i,v in ipairs(SignCountCfg) do
		if count >= v.id then
			table.insert(list, v.id)
		end
	end
	for i,v in ipairs(list) do
		if not Info:IsGetAward(v) then
			return true
		end
	end
	return false
end

--清理缓存
function My:Clear()
	Info:Clear()
	My.isOpen = false
end

--释放资源
function My:Dispose()
	self:RemoveLsnr()
	TableTool.ClearFieldsByName(self,"Event")
end

return My