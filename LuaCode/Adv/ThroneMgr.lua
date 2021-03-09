require("Flag/PropFlag")

ThroneMgr = {Name = "ThroneMgr"}
local My = ThroneMgr

--技能ID列表
My.skiIDs = {}

--字典
--k:技能ID
--v:模块ID
My.skiDic = {}

--响应系统信息事件
My.eRespInfo = Event()

--响应提升等阶事件
My.eRespStep = Event()

--星级发生改变
My.eUpStar = Event()

--等阶发生改变
My.eUpStep = Event()

--响应幻化事件
My.eRespChange = Event()

--响应分解事件
My.eRespCompose = Event()

--响应当前状态
My.eRespStatus = Event()

--分解红点
My.eComposeRed = Event()

--升级红点
My.eAdvRed = Event()

My.flag = PropsFlag:New()--PropFlag:New()

--初始化
function My.Init()
	My.sysID = 6
	My.curSelectId = nil
	My.Len = #ThroneCfg
	My.composeRed = false
	My.advRed = false
	My.Reset()
	My.AddLsnr()
	My.SetSkiIDs()
	PropMgr.eUpdate:Add(My.UpdateProp, My)
end

function My.Reset()
	--当前激活等阶模块星级ID
	--可以用来判断是否已解锁
	My.id = 0
	--当前模块基础ID
	My.bid = 0
	--幻化ID
	My.chgID = 0
	--拥有的精华
	My.essence = 0
	--消耗的精华
	My.accumEssence = 0
	--上一模块星际ID的配置
	My.lastCfg = nil
	--当前模块星级ID的配置
	My.curCfg = ThroneStepCfg[1]
	--当前状态
	My.status = 0
	My.composeRed = false
	My.advRed = false
end

function My.Clear()
	My.Reset()
	PropMgr.eUpdate:Remove(My.UpdateProp, My)
	MountsSkin.Clear()
end

--分解红点
function My.UpdateProp()
	local itemIds = ItemsCfg[6].ids
	local res, GetNum = nil, ItemTool.GetNum
	local isRed = false
    for i=1,#itemIds do
        local id = itemIds[i]
        res = GetNum(id)
        res = res or 0
		if res > 0 then
			isRed = true
		end
	end
	My.composeRed = isRed
	My.eComposeRed(isRed,5)
end

--升级红点判读
function My.UpdateAdvRed()
	local needExp = My.curCfg.con
	local essence = My.essence
	local isRed = false
	if essence > 0 and needExp > 0 then
		isRed = true
	end
	My.advRed = isRed
	My.eAdvRed(isRed,6)
end

--设置技能列表
function My.SetSkiIDs()
	local ids = My.skiIDs
	local dic = My.skiDic
	for i, v in ipairs(ThroneCfg) do
		local skiID = v.oSkiID
		ids[#ids + 1] = skiID
		dic[tostring(skiID)] = v.id
	end
	table.sort(ids)
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
	local cfg = BinTool.Find(ThroneStepCfg, id)
	return cfg
end

--等阶发生改变
function My.StChanged()
	if My.lastCfg == nil then return false end
	if My.lastCfg == My.curCfg then return false end
	return true
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
	Add(28030, My.RespInfo)
	Add(28032, My.RespStep)
	Add(28042, My.RespChange)
	Add(28034,My.RespCompose)
	Add(28036,My.RespEssence)
	Add(28044,My.RespStatus)
end

--响应系统信息
--msg:m_throne_info_toc
function My.RespInfo(msg)
	local mi = msg.throne_info
	local id = mi.throne_id --当前进阶的id
	My.status = mi.status
	if id < 1 then return end
	My.SetCur(id)
	My.essence = mi.throne_essence --当前拥有的精华
	My.accumEssence = mi.accum_essence --当前消耗的精华
	My.chgID = mi.cur_id --当前宝座id
	if(My.chgID < 1) then My.chgID = id end
	My.UpdateAdvRed()
	My.eRespInfo()
	My.IsExistCurThrone()
end

--请求升级
--m_throne_upgrade_tos
function My.ReqStep()
	local msg = ProtoPool.GetByID(28031)
	ProtoMgr.Send(msg)
end

--响应升级
--msg:m_throne_upgrade_toc
function My.RespStep(msg)
	local err = msg.err_code
	if My.CheckErr(err) then return end
	-- UITip.Log("响应升级,成功！")
	local lastBid, lastid = My.bid, My.id
	My.essence = msg.total_essence
	My.accumEssence = msg.accum_essence
	My.SetCur(msg.throne_id)
	if My.bid ~= lastBid then My.eUpStep() end
	if My.id ~= lastid then
		My.eUpStar()
		if(My.chgID < 1) then
			My.chgID = My.id
			My.eRespChange(0)
		end
	end
	My.UpdateAdvRed()
	My.eRespStep()
end

--请求幻化
function My.ReqChange(id)
	local msg = ProtoPool.GetByID(28041)
	msg.throne_id = id
	ProtoMgr.Send(msg)
end

--响应幻化
--msg:m_throne_surface_toc
function My.RespChange(msg)
	local err = msg.err_code
	if My.CheckErr(err) then return end
	My.chgID = msg.throne_id
	My.eRespChange(err)
end

--请求分解
--m_throne_resolve_tos
function My.ReqCompose(idTab)
	local msg = ProtoPool.GetByID(28033)
	for k,v in pairs(idTab) do
		local id = PropMgr.TypeIdById(v)
		msg.resolve_item_id:append(id) 
	end
	ProtoMgr.Send(msg)
end

--响应分解
--m_throne_resolve_toc
function My.RespCompose(msg)
	local err = msg.err_code
	if My.CheckErr(err) then return end
	UITip.Log("分解成功！")
	My.essence = msg.total_essence
	My.UpdateAdvRed()
	My.eRespCompose()
end

--推送精华
function My.RespEssence(msg)
	My.essence = msg.total_essence
	My.UpdateAdvRed()
	My.eRespCompose()
end

--请求设置显示状态
--index(number):状态id   0-隐藏，1-使用
function My.ReqStatus(index)
	local tsStatue = 28043
	local msg = ProtoPool.GetByID(tsStatue)
	if msg == nil then return end
	msg.status = index
	ProtoMgr.Send(msg)
end

--响应状态
function My.RespStatus(msg)
	local status = msg.status
	My.status = status
	My.eRespStatus()
end

--判断当前宝座资源是否存在
function My.IsExistCurThrone()
	if My.chgID == 0 or My.chgID == nil then
		return
	end
	local index = My.chgID % 100 + 1
	local temp  = ThroneCfg[index]
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
		local id = ThroneCfg[1].id
		id = id * 100 + 1
		My.ReqChange(id)
	end
end

function My.CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return true
    end
    return false
end

return My
