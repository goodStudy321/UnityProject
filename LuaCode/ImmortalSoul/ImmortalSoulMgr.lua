--[[
 	authors 	:Liu
 	date    	:2018-11-2 16:00:00
 	descrition 	:仙魂管理类
--]]

ImmortalSoulMgr = {Name = "ImmortalSoulMgr"}

local My = ImmortalSoulMgr

local Info = require("ImmortalSoul/ImmortalSoulInfo")

My.eChangeSoul = Event()

function My:Init()
	Info:Init()
	self:SetLnsr(ProtoLsnr.Add)
	self.eEquip = Event()
	self.eUnload = Event()
	self.eLvUp = Event()
	self.eUpStone = Event()
	self.eUpDecompSet = Event()
	self.eDecomp = Event()
	self.eComp = Event()
	self.eAddSoul = Event()
end

--设置监听
function My:SetLnsr(func)
	func(22934, self.RespImmSoulInfo, self)
	func(22936, self.RespUpImmSoul, self)
	func(22938, self.RespEquip, self)
	func(22940, self.RespSoulLvUp, self)
	func(22942, self.RespSoulComp, self)
	func(22944, self.RespSoulDecomp, self)
	func(22946, self.RespDecompSet, self)
	func(22948, self.RespEquipPos, self)
	func(22950, self.RespUpStone, self)
	func(22952, self.RespUnload, self)
end

--响应仙魂信息
function My:RespImmSoulInfo(msg)
	for i,v in ipairs(msg.use_list) do
		local soulId = v.immortal_soul_id
		local index = v.index
		local lvId = v.level_id
		Info:SetUseList(soulId, index, lvId)
	end
	for i,v in ipairs(msg.bag_list) do
		local soulId = v.immortal_soul_id
		local index = v.index
		local lvId = v.level_id
		Info:SetBagList(soulId, index, lvId)
	end
	for i,v in ipairs(msg.open_pos) do
		Info:SetOpenList(v)
	end
	Info.stone = msg.stone
	Info.debris = msg.dust
	Info.decompSet = msg.auto_bd_type

	-------------------------------------------------------
	-- for i,v in ipairs(msg.use_list) do
	-- 	iTrace.Error("soulId = "..v.immortal_soul_id.."  index = "..v.index.."  lvId = "..v.level_id)
	-- end
	-- for i,v in ipairs(Info.openList) do
	-- 	iTrace.Error("OpenId = "..v)
	-- end
	-- iTrace.Error("debris = "..Info.debris.." stone = "..Info.stone.." isAutoDecomp = "..Info.isAutoDecomp)
	self:IsShowAction()
end

--响应更新仙魂
function My:RespUpImmSoul(msg)
	for i,v in ipairs(msg.del_list) do
		Info:RemoveBagList(v)-----------------------
		-- iTrace.Error("delId = "..v)
	end
	for i,v in ipairs(msg.update_list) do
		local soulId = v.immortal_soul_id
		local index = v.index
		local lvId = v.level_id
		Info:SetBagList(soulId, index, lvId)
	end
	Info.debris = msg.dust
	self:IsShowAction()
end

--请求仙魂镶嵌
function My:ReqEquip(bagId, pos)
	local msg = ProtoPool.GetByID(22937)
	msg.bag_id = bagId
	msg.pos = pos
	ProtoMgr.Send(msg)
end

--响应镶嵌
function My:RespEquip(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local soulId = msg.use.immortal_soul_id
	local index = msg.use.index
	local lvId = msg.use.level_id
	Info:SetUseList(soulId, index, lvId)
	local delId = msg.del_id
	Info:RemoveBagList(delId)
	self.eEquip(delId)
	for i,v in ipairs(msg.add) do
		local soulId1 = v.immortal_soul_id
		local index1 = v.index
		local lvId1 = v.level_id
		Info:SetBagList(soulId1, index1, lvId1)
		self.eAddSoul()
	end
	self:IsShowAction()
end

--请求卸下
function My:ReqUnload(pos)
	local msg = ProtoPool.GetByID(22951)
	msg.pos = pos
	ProtoMgr.Send(msg)
end

--响应仙魂卸下
function My:RespUnload(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local soulId = msg.bag_add.immortal_soul_id
	local index = msg.bag_add.index
	local lvId = msg.bag_add.level_id
	Info:SetBagList(soulId, index, lvId)
	local pos = msg.pos
	Info:RemoveUseList(pos)
	self.eUnload(pos)
	self:IsShowAction()
end

--请求升级
function My:ReqLvUp(pos)
	local msg = ProtoPool.GetByID(22939)
	msg.pos = pos
	ProtoMgr.Send(msg)
end

--响应升级
function My:RespSoulLvUp(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	Info.debris = msg.dust
	self.eLvUp(msg.pos, msg.level_id)
	self:IsShowAction()
end

--请求仙魂合成
function My:ReqSoulComp(compId, indexList)
	local msg = ProtoPool.GetByID(22941)
	msg.immortal_soul_id = compId
	for i,v in ipairs(indexList) do
		msg.bag_list:append(v)
	end
	ProtoMgr.Send(msg)
end

--响应仙魂合成
function My:RespSoulComp(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	for i,v in ipairs(msg.del_list) do
		Info:RemoveBagList(v)
		Info:RemoveUseList(v)
	end
	local soulId = msg.immortal_soul.immortal_soul_id
	local index = msg.immortal_soul.index
	local lvId = msg.immortal_soul.level_id
	if index > 200 then
		Info:SetUseList(soulId, index, lvId)
	else
		Info:SetBagList(soulId, index, lvId)
	end
	for i,v in ipairs(msg.add) do
		local soulId1 = v.immortal_soul_id
		local index1 = v.index
		local lvId1 = v.level_id
		Info:SetBagList(soulId1, index1, lvId1)
	end
	Info.stone = msg.stone
	Info.debris = msg.dust
	self.eComp()
	self:IsShowAction()
end

--请求仙魂分解
function My:ReqSoulDecomp(indexList)
	local msg = ProtoPool.GetByID(22943)
	for i,v in ipairs(indexList) do
		msg.bag_id:append(v)
	end
	ProtoMgr.Send(msg)
end

--响应仙魂分解
function My:RespSoulDecomp(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	Info.debris = msg.dust
	Info.stone = msg.stone
	for i,v in ipairs(msg.del_list) do
		Info:RemoveBagList(v)
	end
	for i,v in ipairs(msg.add_list) do
		local soulId = v.immortal_soul_id
		local index = v.index
		local lvId = v.level_id
		-- iTrace.Error("id = "..soulId.." index = "..index.." lvId = "..lvId.." len = "..#msg.add_list)
		Info:SetBagList(soulId, index, lvId)
	end
	self.eDecomp()
	self:IsShowAction()
end

--请求分解设置(type为品质1~5)
function My:ReqDecompSet(type)
	local msg = ProtoPool.GetByID(22945)
	msg.bd_type = type
	ProtoMgr.Send(msg)
end

--响应分解设置
function My:RespDecompSet(msg)
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	self.eUpDecompSet()
end

--响应镶嵌位置
function My:RespEquipPos(msg)
	for i,v in ipairs(msg.pos) do
		Info:SetOpenList(v)
	end
	self:IsShowAction()
end

--响应更新仙魂石
function My:RespUpStone(msg)
	Info.stone = msg.stone
	self.eUpStone()
end

--判断是否显示红点
function My:IsShowAction()
	local isOne, isTwo = Info:GetActionList()
	local isDecomp = Info:IsDecomp()
	local isUp = false
	local list = Info:GetLvUpList()
	for i,v in ipairs(list) do
		if v ~= 0 then
			isUp = true
			break
		end
	end
	local actId = ActivityMgr.XH
	if isOne or isTwo or isDecomp or isUp then
		self.eChangeSoul(true)
		SystemMgr:ShowActivity(actId)
	else
		self.eChangeSoul(false)
		SystemMgr:HideActivity(actId)
	end
end

--清理缓存
function My:Clear()
    Info:Clear()
end
    
--释放资源
function My:Dispose()
	self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
end

return My