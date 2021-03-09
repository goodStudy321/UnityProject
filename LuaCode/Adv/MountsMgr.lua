--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-18 12:32:15
-- 坐骑管理器
--==============================================================================

require("Adv/MountsSkin")
require("Flag/PropFlag")

local GetErr = ErrorCodeMgr.GetError
MountsMgr = {Name = "MountsMgr"}
local My = MountsMgr

--技能ID列表
My.skiIDs = {}

--字典
--k:技能ID
--v:模块ID
My.skiDic = {}

--资质丹信息 k:id v:已使用数量
My.qualDic = {}

--响应系统信息事件
My.eRespInfo = Event()

--响应提升等阶事件
My.eRespStep = Event()

--星级发生改变
My.eUpStar = Event()

--等阶发生改变
My.eUpStep = Event()

--响应提升资质事件
My.eRespQual = Event()

--响应幻化事件
My.eRespChange = Event()

My.flag = PropsFlag:New()--PropFlag:New()

--初始化
function My.Init()
	My.sysID = 1
	My.curSelectId = nil
	My.Len = My.GetLen()
	My.Reset()
	My.AddLsnr()
	My.SetSkiIDs()
	MountsSkin.Init()
	-- My.flag:Init(My.GetConID())
	My.qualIDs = My.GetQualIds(MountQualCfg)
	My.flag:Init(My.GetConID(),My.qualIDs,nil,1)
end

function My.Reset()
	--当前激活等阶模块星级ID
	--可以用来判断是否已解锁
	My.id = 0
	--当前模块基础ID
	My.bid = 0
	--幻化(基础)ID
	My.chgID = 0
	--拥有的经验
	My.exp = 0
	--上一模块星际ID的配置
	My.lastCfg = nil
	--当前模块星级ID的配置
	My.curCfg = MountStepCfg[1]

	My.SetQualKey()
end

function My.Clear()
	My.Reset()
	MountsSkin.Clear()
end

function My.GetLen()
	local index = 0
	local len = #MountCfg
	for i=1,len do
		local temp = MountCfg[i]
		if temp.type == 0 then
			index = index + 1
		end
	end
	return index
end

--设置技能列表
function My.SetSkiIDs()
	local ids = My.skiIDs
	local dic = My.skiDic
	for i, v in ipairs(MountCfg) do
		local skiID = v.oSkiID
		ids[#ids + 1] = skiID
		dic[tostring(skiID)] = v.id
	end
	table.sort(ids)
end

--设置资质字典的 Key
function My.SetQualKey()
	local dic = My.qualDic
	for i, v in ipairs(MountQualCfg) do
		local k = tostring(v.id)
		dic[k] = 0
	end
end

--设置资质字典的 Value
function My.SetQualVal(lst)
	if lst == nil then return end
	local dic, k = My.qualDic, nil
	for i, v in ipairs(lst) do
		k = tostring(v.id)
		dic[k] = v.val
	end
end

--判断技能是否锁定
--skiID:技能ID
function My.GetSkiLock(skiID)
	local k = tostring(skiID)
	local id = My.skiDic[k]
	local bid = My.GetBaseID(My.curCfg.id)
	local res = ((id > bid) and true or false)
	return res
end

--通过坐骑星级ID获取基础ID
function My.GetBaseID(id)
	local bid = id * 0.01
	bid = math.floor(bid)
	do return bid end
end

--获取当前坐骑星级配置
function My.GetCur()
	local cfg = My.GetCfg(My.id)
	return cfg
end

--获取下一星级坐骑配置
function My.GetNext()
	local nextID = My.curCfg.id + 1
	local cfg = My.GetCfg(nextID)
	return cfg
end

--通过ID获取坐骑进阶配置
--id(number):星级ID
function My.GetCfg(id)
	local cfg = BinTool.Find(MountStepCfg, id)
	return cfg
end

--等阶发生改变
function My.StChanged()
	if My.lastCfg == nil then return false end
	if My.lastCfg == My.curCfg then return false end
	return true
end

--获取消耗道具ID
function My.GetConID()
	-- do return 30301 end
	local itemCfg = ItemsCfg[5]
	if not itemCfg then
		iTrace.eError("GS","请检查坐骑消耗配置")
		return
	end
	return itemCfg.ids
end

--获取资质丹药IDs
function My.GetQualIds(iQualCfg)
	local qualTab = {}
	for k,v in pairs(iQualCfg) do
		if qualTab[v.id] == nil then
			qualTab[v.id] = v
		end
	--   table.insert(qualTab,v.id)
	end
	return qualTab
end

--设置当前星级ID
function My.SetCur(id)
	My.id = id
	My.lastCfg = My.curCfg
	My.curCfg = My.GetCur(id)
	My.bid = My.GetBaseID(id)
end

--添加事件监听
function My.AddLsnr()
	local Add = ProtoLsnr.Add
	Add(20270, My.RespInfo)
	Add(20272, My.RespStep)
	Add(20274, My.RespQual)
	Add(20276, My.RespChange)
end

--响应系统信息
--msg:m_mount_info_toc
function My.RespInfo(msg)
	local mi = msg.mount_info
	local id = mi.mount_id
	if id < 1 then return end
	My.SetCur(id)
	My.exp = mi.exp
	My.chgID = mi.cur_id
	if(My.chgID < 1) then My.chgID = id end
	My.SetQualVal(mi.quality_list)
	MountsSkin.Set(mi.skin_list)
	My.eRespInfo()
	local mountStep = (My.bid % 10) + 1
	mountStep = math.modf(mountStep)
	local isFullStep = false
	local isFullQual = true
	local qualTab = My.flag.getQualById
	local isFullQualTab = My.flag.isFullQualTab
	for i, v in pairs(mi.quality_list) do
		local k = v.id
		if qualTab[k] then
		  local usedNum = v.val
		  local maxUseNum = AdvMgr:GetUseMax(qualTab[k])
		  if usedNum >= maxUseNum then
			isFullQualTab[k].isFull = true
		  end
		end
	end
	-- if mi.quality_list == nil or #mi.quality_list == 0 then
	-- 	isFullQual = false
	-- end

	local curExp = My.exp
	local curCfg = My.GetCfg(id)
	local needExp = curCfg.con
	local exp = needExp - curExp
	My.flag.needExp = exp
	
	if mountStep == My.Len and My.curCfg.st == 10 then
		isFullStep = true
	end
	My.flag.isFullStep = isFullStep
	My.flag.isFullQual = isFullQual
	My.flag.isFullQualTab = isFullQualTab
	My.flag:Update()
	iTrace.sLog("Loong", "响应坐骑信息:", msg)
	My.IsExistCurPet()
end

--判断当前坐骑资源是否存在
function My.IsExistCurPet()
	if My.chgID == 0 or My.chgID == nil then
		return
	end
	local index = My.chgID % 100 + 1
	local temp  = MountCfg[index]
	if not temp then return end
	local modeId = temp.uMod
	local mod = temp.mod
	modeId = tostring(modeId)
	mod = tostring(mod)
	local modeTemp = RoleBaseTemp[modeId]
	local mode = RoleBaseTemp[mod]
	local modePath = modeTemp.path
	local path = mode.path
	local isExist = AssetTool.IsExistAss(modePath)
	local isScExist = AssetTool.IsExistAss(path)
	if isExist == true and isScExist == true then
		return
	elseif isExist == false or isScExist == false then
		My.ReqChange(MountCfg[1].id)
	end
end


--请求升阶
function My.ReqStep()
	local id = My.curSelectId--My.GetConID()
	local uid = PropMgr.TypeIdById(id)
	PropMgr.ReqUse(uid, 1)
	--iTrace.eLog("Loong", "坐骑请求升阶:", msg)
end

--响应等阶
--msg:m_mount_step_toc
function My.RespStep(msg)
	local err = msg.err_code
	if err > 0 then
		My.flag.needExp = nil
		My.flag.isFullStep = true
		My.flag:Update()
		MsgBox.ShowYes(GetErr(err))
	else
		local lastBid, lastid = My.bid, My.id
		My.exp = msg.exp
		My.SetCur(msg.mount_id)

		local curExp = msg.exp
		local curCfg = My.GetCfg(msg.mount_id)
		local needExp = curCfg.con
		local exp = needExp - curExp
		My.flag.needExp = exp

		My.flag:Update()
		if My.bid ~= lastBid then My.eUpStep() end
		if My.id ~= lastid then
			My.eUpStar()
			if(My.chgID < 1) then
				My.chgID = My.id
				My.eRespChange(0)
			end
		end
	end
	My.eRespStep(err)
	--Trace.eLog("Loong", "坐骑响应升阶:", msg)
end

--响应提升资质
--msg:m_mount_quality_toc
function My.RespQual(msg)
	local kv = msg.quality
	local k = tostring(kv.id)
	My.qualDic[k] = kv.val

	local isFullQualTab = My.flag.isFullQualTab
	local qualTab = My.flag.getQualById
	local kid = kv.id
	if qualTab[kid] then
		local usedNum = kv.val
		local maxUseNum = AdvMgr:GetUseMax(qualTab[kid])
		if usedNum >= maxUseNum then
			isFullQualTab[kid].isFull = true
		end
	end
	My.flag.isFullQualTab = isFullQualTab
	My.flag:Update()

	My.eRespQual()
	--iTrace.eLog("Loong", "坐骑响应资质:", msg)
end

--请求幻化
function My.ReqChange(id)
	local msg = ProtoPool.GetByID(20275)
	msg.cur_id = id
	ProtoMgr.Send(msg)
	--iTrace.eLog("Loong", "坐骑请求幻化:", msg)
end

--响应幻化
--msg:m_mount_change_toc
function My.RespChange(msg)
	local err = msg.err_code
	if err > 0 then
		MsgBox.ShowYes(GetErr(err))
	else
		My.chgID = msg.cur_id
	end
	My.eRespChange(err)
	--iTrace.eLog("Loong", "坐骑响应幻化:", msg)
end


return My
