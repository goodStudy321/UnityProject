--region MoneyTreeMgr.lua
--Date
--此文件由[HS]创建生成

require("Data/MoneyTree/MoneyTreeNetwork")
MoneyTreeMgr = {Name="MoneyTreeMgr"}
local M = MoneyTreeMgr

--最大记录数
local MaxRecord = 30
local DesKey = "101"
local DesLog1 = "102"
local DesLog2 = "103"
local DesLog3 = "104"
local TipKey = "105"
local VipKey = "106"
local InvestKey = "107"
local NameKey = "109"
local LimitKey1 = "110"
local LimitKey2 = "111"

M.eNum = Event()
M.eUserLog = Event()
M.ePlayerLog = Event()
M.eGetMoney = Event()
M.eRed = Event()

function M:Init()
	self.PlayerLuck = {}
	self.UserRecord = {}
	self.UseNum = 0
	MoneyTreeNetwork:Init()
end
--==============================--
--desc:协议返回数据处理
--==============================---
--更新使用次数
function M:UpdateUseNum(num)
	self.UseNum = num
	self.eNum()
	
	local cost = self:GetCostForVip()
	if cost then
		local status = cost.v == 0
		self.eRed(status)
		if OpenMgr:IsOpen(709) == true then
			local actId = ActivityMgr.DJ
			if status == true then
				SystemMgr:ShowActivity(actId,14)
			else
				SystemMgr:HideActivity(actId,14)
			end
		end
	end
end
--更新个人日志
function M:UpdateUserRecord(rote, money, init)
	if not rote then rote = 1 end
	money = UIMisc.ToString(money)
	local str = nil
	if rote == 1 then
		str = string.format(StrTool.GetDes(DesLog1), money)
	else
		str = string.format(StrTool.GetDes(DesLog2),rote, money)
	end
	local logs= self.UserRecord
	table.insert(logs, str)
	if #logs > MaxRecord then
		table.remove(logs, 1)
	end
	if not init then
		self.eUserLog(true, rote > 1)
	end
end
--其他玩家日志
function M:UpdatePlayerLuck(name, rote, money, init)
	money = UIMisc.ToString(money)
	if not name then name = StrTool.GetDes(NameKey) end
	local str = string.format(StrTool.GetDes(DesLog3),name, rote, money )
	local logs = self.PlayerLuck
	table.insert(logs, str)
	if #logs > MaxRecord then
		table.remove(logs, 1)
	end
	if not init then
		self.ePlayerLog()
	end
end

--==============================--
--desc:请求协议交互
--==============================--
function M:Use()
	local lv,limit,nextlv,nextLimit = self:GetLimitForVip()
	if self.UseNum >= limit then
		if nextlv == 0 then
			MsgBox.ShowYesNo(StrTool.GetDes(LimitKey1))
		else
			MsgBox.ShowYesNo(StrTool.GetDes(LimitKey2,self.BuyVip, self))
		end
		return
	end

	local RA = RoleAssets 
	local num = self.UseNum + 1
	local temp = MoneyTreeCostTemp[num]
	if temp then
		local cost = temp.cost
		if RA.IsEnoughAsset(cost.k, cost.v) == false then
			local name = string.format(StrTool.GetDes(InvestKey), RA:GetTypeName(cost.k))		
			if cost.k == 2 then
				MsgBox.ShowYesNo(name,self.Invest, self)
			else
				MsgBox.ShowYesNo(name)
			end
			return
		end
	end
	MoneyTreeNetwork:ReqMoneyTreeITos()
end

--==============================--
--desc:获取数据
--==============================--
--vip等级/总次数/下一等级/下一级次数
function M:GetLimitForVip()
	local lv = VIPMgr.GetVIPLv()
	local nextlv = 0
	local limit = 0
	local nextLimit = 0
	local temp = VIPLv[lv + 1]
	if temp then
		limit = temp.moneyTree
	end
	local next = VIPLv[lv + 2]
	if next then
		nextlv = next.lv
		nextLimit = next.moneyTree
	end
	return lv, limit, nextlv, nextLimit
end

--获取消耗
function M:GetCostForVip()
	local temp = MoneyTreeCostTemp[self.UseNum + 1]
	if temp then
		return temp.cost
	end
	return nil
end

--描述文本
function M:GetDes()
	return StrTool.GetDes(DesKey)
end

--提示文本
function M:GetTip()
	return StrTool.GetDes(TipKey)
end

--==============================--
--desc:打开其他UI
--==============================--
--购买
function M:BuyVip()
	VIPMgr.OpenVIP()
end
--充值
function M:Invest()
	VIPMgr.OpenVIP(1)
end

function M:Clear()
	local luck = self.PlayerLuck
	local len = #luck
	while len > 0 do
		table.remove(luck, len)
		len = #luck
	end
	local record = self.UserRecord
	local len = #record
	while len > 0 do
		table.remove(record, len)
		len = #record
	end
	self.UseNum = 0
end

function M:Dispose()
end

return M