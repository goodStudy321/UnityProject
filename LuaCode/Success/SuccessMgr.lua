--[[
 	authors 	:Liu
 	date    	:2018-8-31 15:20:00
 	descrition 	:成就管理
--]]

SuccessMgr = {Name = "SuccessMgr"}

local My = SuccessMgr

My.Info = require("Success/SuccessInfo")

function My:Init()
	My.Info:Init()
	self.isAction = false
	self.eGetAward = Event()
	self.eChangeAction = Event()
	self:SetLnsr(ProtoLsnr.Add)

	self.actionList = {}
end

--设置监听
function My:SetLnsr(func)
	func(22900, self.RespSuccInfo, self)
	func(22902, self.RespSuccCondInfo, self)
	func(22904, self.RespSuccAwardInfo, self)
end

--响应成就信息
function My:RespSuccInfo(msg)
	-- iTrace.Error("msg = "..tostring(msg))
	--是否播放成就动画
	self.isShow = true
	for i,v in ipairs(msg.conditions) do
		local type = v.type
		for i,v in ipairs(v.id_list) do
			local id = tonumber(v.id)
			local val = tonumber(v.val)
			My.Info:SetCondDic(type, id, val)
			My.Info:SetOldDic(type, id, val)
		end
	end
	for i,v in ipairs(msg.reward_list) do
		local key = tostring(v)
		My.Info.getDic[key] = true
	end

	self:UpAction()
end

--响应成就条件信息(达成某一成就条件时，推送)
function My:RespSuccCondInfo(msg)
	-- iTrace.Error("msg1 = "..tostring(msg))
	if self.isShow == nil then return end
	local type = msg.type
	local id = msg.id
	local val = msg.val
	My.Info:SetCondDic(type, id, val)
	self:SetAnimList(type, id, val)
	if #My.Info.animList > 0 then
		UIMgr.Open(UISuccessShow.Name)
	end
	My.Info:SetOldDic(type, id, val)

	local isShow = self:IsShowAction(type, id, val)
	if isShow then self.eChangeAction(isShow) end
end

--请求成就奖励
function My:ReqSuccAward(id)
	if UISuccess then UISuccess:Lock(true) end
	local msg = ProtoPool.GetByID(22903)
	msg.achievement_id = id
	ProtoMgr.Send(msg)
end

--响应成就奖励信息
function My:RespSuccAwardInfo(msg)
	-- iTrace.Error("msg2 = "..tostring(msg))
	if UISuccess then UISuccess:Lock(false) end
	local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	local id = msg.achievement_id
	local key = tostring(id)
	My.Info.getDic[key] = true

	-- self:UpGetList(id)
	self.eGetAward(id)
	self.isAction = #My.Info.getList > 0
	self.eChangeAction(self.isAction)
end

--设置成就动画列表
function My:SetAnimList(type, id, val)
	local key = tostring(type)
	local oldVal = 0
	local dic = My.Info.oldDic[key]
	if dic then
		for i,v in ipairs(dic.idList) do
			if v == id then
				oldVal = dic.valList[i]
			else
				oldVal = 0
			end
		end
	end

	local list = My.Info.switchDic[key]
	if list == nil then return end
	for i,v in ipairs(list) do
		local key = tostring(v)
		local cfg = SuccessCfg[key]
		if cfg == nil then return end
		if cfg.condId == id then
			local isGeted = My.Info.getDic[key]--是否已领取
			local cond = cfg.condition--条件
			local isOld = (oldVal~=0) and oldVal >= cond or false--是否是旧的
	
			if val >= cond and not isOld and not isGeted then
				local id = cfg.id
				local key = tostring(id)
				if not My.Info.compDic[key] then
					table.insert(My.Info.animList, id)
				end
			end
		end

	end
end

--获取红点列表
function My:GetActionList()
	My.Info:ClearList()
	ListTool.Clear(self.actionList)
	for k,v in pairs(My.Info.condDic) do
		local list = My.Info.switchDic[k]
		if list == nil then return end
		for i1,v1 in ipairs(list) do
			local key = tostring(v1)
			for i2,v2 in ipairs(v.idList) do
				local cfg = SuccessCfg[key]
				if cfg == nil then return end
				if cfg.condId == v2 and v.valList[i2] >= cfg.condition then
					My.Info.isOpen = true
					if not My.Info.getDic[key] then
						My.Info:SetGetList(v1)
						table.insert(self.actionList, v1)
						break
					end
				end
			end
		end
	end
	return self.actionList
end

-- --更新获取列表
-- function My:UpGetList(k)
-- 	local key = tostring(k)
-- 	local condDic = My.Info.condDic[key]
-- 	if condDic == nil then return end
-- 	local list = My.Info.switchDic[key]
-- 	if list == nil then return end

-- 	for i,v in ipairs(list) do
-- 		local cfg = SuccessCfg[tostring(v)]
-- 		if cfg == nil then return end
-- 		for i1,v1 in ipairs(condDic.idList) do
-- 			if cfg.condId == v1 and condDic.valList[i1] >= cfg.condition then
-- 				return
-- 			end
-- 		end
-- 	end
-- 	My.Info:RemoveGetList(k)
-- end

--是否显示红点
function My:IsShowAction(key, id, val)
	if #My.Info.getList > 0 then return true end

	local list = My.Info.switchDic[tostring(key)]
	if list == nil then return end

	for i,v in ipairs(list) do
		local cfg = SuccessCfg[tostring(v)]
		if cfg == nil then return end
		if cfg.condId == id and val >= cfg.condition then
			if not My.Info.getDic[tostring(v)] then
				table.insert(My.Info.getList, v)
				My.Info.isOpen = true
				self.isAction = true
				return true
			end
		end
	end
	return false
end

--检查红点
function My:CheckAction()
	local list = self:GetActionList()
	local actionList = {}
	local cfg = SuccessCfg
	for i,v in ipairs(list) do
		local key = tostring(v)
		table.insert(actionList, cfg[key].succType)
	end
	return actionList
end

--更新红点
function My:UpAction()
	local actId = ActivityMgr.CJ

	local list = self:CheckAction()
	self.isAction = #list > 0
	self.eChangeAction(self.isAction)
end

--清理缓存
function My:Clear()
	self.isShow = nil
	My.Info:Clear()
end

--释放资源
function My:Dispose()
	self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
end

return My