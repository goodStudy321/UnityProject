--[[
 	authors 	:Liu
 	date    	:2019-4-9 20:40:00
 	descrition 	:化神投资管理类
--]]

LvInvestMgr = {Name = "LvInvestMgr"}

local My = LvInvestMgr

--投资档次
My.investGold = 0
--奖励字典
My.investDic = {}
--当前档次的立返元宝
My.maxGold = 0

function My:Init()
	self.eInvestBuy = Event()
	self.eInvestAward = Event()
	self:SetLnsr(ProtoLsnr.Add)
	UserMgr.eLvEvent:Add(self.LvChange, self)
end

--设置监听
function My:SetLnsr(func)
	func(22580, self.RespInvestInfo, self)
	func(22582, self.RespInvestBuy, self)
	func(22584, self.RespInvestAward, self)
end

--响应化神投资信息
function My:RespInvestInfo(msg)
	My.investGold = msg.summit_invest_gold
	for i,v in ipairs(msg.reward_list) do
		local key = tostring(v.id)
		My.investDic[key] = v.val
	end
	self:UpAction()
end

--请求化神投资购买
function My:ReqInvestBuy(gold)
	local msg = ProtoPool.GetByID(22581)
	msg.summit_invest_gold = gold
	ProtoMgr.Send(msg)
end

--响应化神投资购买
function My:RespInvestBuy(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	My.investGold = msg.summit_invest_gold
	self.eInvestBuy()
	self:UpAction()
end

--请求化神投资奖励
function My:ReqInvestAward(lv)
	local msg = ProtoPool.GetByID(22583)
	msg.level = lv
	ProtoMgr.Send(msg)
end

--响应化神投资奖励
function My:RespInvestAward(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local key = tostring(msg.reward.id)
	My.investDic[key] = msg.reward.val
	self.eInvestAward()
	self:UpAction()
end

--获取投资档次
function My:GetType(gold)
    local cfg = GlobalTemp["116"]
    for i,v in ipairs(cfg.Value2) do
        if v == gold then
            return i
        end
    end
    return nil
end

--根据档次获取元宝数量
function My:GetCount(id, type)
	local cfg, index = BinTool.Find(LvInvestCfg, id)
	if cfg == nil then return end
	local num = 0
	local list = cfg["type"..type]
	for i,v in ipairs(list) do
		if v.id == 3 then
			num = v.num
		end
	end
	local gold = My.investDic[tostring(id)]
	if gold then
		local total = self:GetTotalCount(id, type)
		local type1 = self:GetType(gold)
		local count = self:GetTotalCount(id, type1)
		num = total - count
	end
	return num
end

--根据档次获取元宝总数量
function My:GetTotalCount(id, type)
	local cfg, index = BinTool.Find(LvInvestCfg, id)
	if cfg == nil then return end
	local num = 0
	for i=1, type do
		local list = cfg["type"..i]
		for i,v in ipairs(list) do
			if v.id == 3 then
				num = v.num + num
			end
		end
	end
	return num
end

--是否开启
function My:IsOpen()
	local curInvest = InvestMgr.curInvest
	local lv = GlobalTemp["31"].Value3
	if User.MapData.Level >= lv then
		if curInvest == 0 then
			return true
		else
			local dic = InvestMgr.investData.dic
			for k,v in pairs(dic[tostring(curInvest)]) do
				if v.hadGet == 1 then
					return false
				end
			end
		end
	else
		return false
	end
	return true
end

--响应等级变化
function My:LvChange()
    self:UpAction()
end

--更新红点
function My:UpAction()
	local len = 0
	local lv = User.MapData.Level
	for i,v in ipairs(LvInvestCfg) do
		if lv >= v.id then
			len = len + 1
		end
	end
	for k,v in pairs(My.investDic) do
		if v == My.investGold then
			len = len - 1
		end
	end
	VIPMgr.UpAction(8, len>0)
end

--清理缓存
function My:Clear()
	My.maxGold = 0
	My.investGold = 0
	My.investDic = {}
end
    
--释放资源
function My:Dispose()
	self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
	UserMgr.eLvEvent:Remove(self.LvChange, self)
end

return My