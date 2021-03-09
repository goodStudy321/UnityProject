--[[

]]
require("Data/SecretArea/LatticeData")
require("Data/SecretArea/MinRoleData")
require("Data/SecretArea/SecretAreaNetWork")

SecretAreaMgr={Name="SecretAreaMgr"}
local M = SecretAreaMgr

M.isOpen=false
M.isJoin=false


--------參數
local NW = SecretAreaNetwork
--範圍
M.Rect = GlobalTemp["166"].Value2

--地图数据
M.LatticeDic={} --key:x_y
--九宫数据
M.NightRoundDic={}
--仓库奖励资源
M.GoodsList={}

--玩家位置
M.Origin = {}
M.Origin.x = 0
M.Origin.y = 0

--战力
M.Power = 0
--采集次数
M.CollectNum = 0
--采集结束时间
M.CollectEndTime = 0
--是否有道庭加成
M.isFamilyAdd=0
--移动次数
M.MoveNum = 0
--鼓舞次数p
M.InspireNum = 0
--拦截记录  k,v = [number, string]
M.PlunderHistory = {}
--拦截红点状态
M.IsPlunderRed=false 
--活动时间计时器
M.timer = ObjPool.Get(DateTimer)
--资源红点状态
M.IsGoodRed=false 

-- --是否可以移动
-- M.IsMove = false

--活动时间计时
M.eTime = Event()
--初始数据更新
M.eInit = Event()
--更新移动次数
M.eMoveNum = Event()
--更新九宫状态
M.eNight = Event()
--鼓舞次数
M.eInspireNum = Event()
--更新主角数据
M.ePlayerInfo=Event()
--点击格子
M.eClickCell = Event()
--更新拦截
M.ePlunderHistory = Event()
--单个格子数据更新
M.eUpdateCellInfo = Event()
--更新资源
M.eGood=Event()

function M.Init()
    M.timer.invlCb:Add(M.CountTime, M)
    NW.Init()
end

--==============================--
function M.UpdateInfo(msg)
    M.UpdateCollectInfo(msg.gather_num, msg.gather_stop_time,msg.is_family_add)
    M.UpdateMoveInfo(msg.shift_num)
    M.UpdateInspireNum(msg.inspire)
    M.UpdateCellsInfo(msg.shift_history)
    M.UpdatePlunderHistroryList(msg.plunder_history)
    M.UpdateGoodsList(msg.goods_list)
    M.UpdateNightRoundList(msg.lattice_list)
    M.eInit()
end

--更新采集次数
function M.UpdateCollectInfo(num, time,is_family_add, isEvent)
    if isEvent == nil then isEvent = false end
    M.CollectNum = num
    M.CollectEndTime = time
    M.isFamilyAdd=is_family_add
end

--更新剩余移动次数
function M.UpdateMoveInfo(num, isEvent)
    if isEvent == nil then isEvent = false end
    M.MoveNum = num
    if isEvent == true then M.eMoveNum() end
end

--更新激励次数
function M.UpdateInspireNum(num,isEvent)
    if isEvent == nil then isEvent = false end
    M.InspireNum=num          --鼓舞次数
    if isEvent == true then
        M.eInspireNum()
    end
end

--更新已探索格子数据队列
function M.UpdateCellsInfo(list)
    if list then
        for i,v in ipairs(list) do
            M.UpdateCellInfo(v)
        end
    end   
end

--更新格子数据
function M.UpdateCellInfo(msg, isEvent)
    if isEvent == nil then isEvent = false end
    local x = msg.x
    local y = msg.y
    local type_id = msg.type_id
    local key =  string.format("%s_%s",x,y)
    local info = M.LatticeDic[key] 
    if not info then 
        M.LatticeDic[key] = {}
        info = M.LatticeDic[key]
    end
    info.key = key
    info.x = msg.x
    info.y = msg.y
    info.num=msg.surplus_num
    info.type_id = msg.type_id             --资源类型
end

--更新拦截list
function M.UpdatePlunderHistroryList(list)
    local len = #list
    if len > 0 then
        for i=1,len do
            M.UpdatePlunderHistrory(list[i])
        end
    end
    M.ePlunderHistory()
end

--更新拦截历史
function M.UpdatePlunderHistrory(msg, isEvent)
    if isEvent == nil then isEvent = false end
    local id = msg.id
    local name = msg.str
    if M.Contains(M.PlunderHistory, id, "k") == -1 then
        local info = {}
        info.k = id
        info.v = name
        table.insert(M.PlunderHistory, info)
        if isEvent == true then
            M.IsPlunderRed= #M.PlunderHistory>0            --拦截红点
            M.UpdateRed()
            M.ePlunderHistory()
        else
            M.ReadPlunderRed()
        end
    end
end

function M.UpdateRed()
    local status = M.IsPlunderRed == true or M.IsGoodRed
    local actId = ActivityMgr.DJ
    if status then
        SystemMgr:ShowActivity(actId,12)
    else
        SystemMgr:HideActivity(actId,12)
    end
end

--更新获得的道具list
function M.UpdateGoodsList(list)
    ListTool.ClearToPool(M.GoodsList)
    if list then
        local len = #list
        for i=1,len do
            local pkv = list[i]
            local kv = ObjPool.Get(KV)
            kv:Init(pkv.id,pkv.val)
            table.insert(M.GoodsList, kv)
        end
    end
    local state = #M.GoodsList>0 and true or false
    M.IsGoodRed=state
    M.UpdateRed()
    M.eGood()
end

--更新九宫数据
function M.UpdateNightRoundList(list, isEvent)
    if isEvent == nil then isEvent = false end
    if isEvent == true then
        M.eNight(false)
        TableTool.ClearDic(M.NightRoundDic)
    end
    local len = #list
    for i=1,len do
        M.UpdateNightRound(list[i], isEvent)     
    end
    if isEvent == true then
        M.eNight(true)
    end
end

--更新格子信息
function M.UpdateNightRound(msg, isEvent)
    if isEvent == nil then isEvent = false end
    M.UpdateCellInfo(msg)
    local info = {}
    info.x = msg.x
    info.y = msg.y
    info.key = string.format("%s_%s", info.x, info.y)
    info.type_id = msg.type_id
    info.num = msg.surplus_num
    info.time = msg.renovate_time
    info.role = M.UpdateRole(msg.mining_role)
    if info.role ~= nil then
        if info.role.role_id == User.MapData.UIDStr then
            M.Origin.x = info.x
            M.Origin.y = info.y
            M.Power = info.role.power
            M.ePlayerInfo()
        end
    end
    M.NightRoundDic[info.key] = info
    if isEvent == true then
        M.eUpdateCellInfo(info.key)
    end
end

--更新角色信息
function M.UpdateRole(msg)
    if msg == nil then return nil end
    local roleid = msg.role_id
    if roleid == 0 then return nil end
    local role = {}
    role.x = msg.x
    role.y = msg.y
    role.key = string.format("%s_%s", role.x, role.y)
    role.type_id = msg.type_id
    role.role_id = msg.role_id
    role.name = msg.role_name
    role.cate = msg.category
    role.sex = msg.sex
    role.fid = msg.family_id
    role.power = msg.power
    role.isFamilyAdd=msg.is_family_add
    return role
end

--///////////////////////////////////////////////

--列表是否包含 value
function M.Contains(list, value, key)
  local index = -1
  if not list then return index end
  local len = #list
  for i=1,len do
    if list[i][key] == value then
      index = i
      break
    end
  end
  return index
end

--可移动区域
function M.IsMoveArea(x,y)
    local ox = M.Origin.x
    local oy = M.Origin.y
    local tx,ty = M.ChangeHV(ox, oy+1)
    if tx == x and ty == y then 
        return true 
    end
    local bx,by = M.ChangeHV(ox, oy-1)
    if bx == x and by == y then 
        return true 
    end
    local lx,ly = M.ChangeHV(ox-1, oy)
    if lx == x and ly == y then 
        return true 
    end
    local rx,ry = M.ChangeHV(ox+1, oy)
    if rx == x and ry == y then 
        return true 
    end
    return false
end

function M.ChangeHV(h,v)
	local mh = M.Rect[1]
    local mv = M.Rect[2]
	h = math.fmod(h, mh ) 
	v = math.fmod(v, mv ) 
	if h > mh then
		mh = h - mh
	elseif h < 1 then
		h = mh - math.abs(h) 
	end
	if v > mv then
		v = v - mv
	elseif v < 1 then
		v = mv - math.abs(v) 
	end
	return h, v
end
--==============================---
--请求初始化信息
function M.ReqInfo()
    if LuaTool.Length(M.Origin) == false then return end
    NW.ReqRoleInfo()
end

--==============================---

function M.IsOpen()
    local active = ActiveInfo["10013"]
    if not active then iTrace.eError("xiaoyu","活动配置表无秘境探索配置")return end
    local lv = active.needLv
    return User.instance.MapData.Level>=lv,active,active.needLv
end

function M.Open()
    M.isOpen=false
    local isOpen,active = M.IsOpen()
    if isOpen==false then return end
    local begDay=active.begDay[1]
    local begTime = active.begTime
    local lastTime = active.lastTime
    local isday = false
    local now = os.date("*t")
    local today = os.date("%w")
    if today=="0" then today="7" end
    local h=begTime[1].k
    local m = begTime[1].v
    local seconds = nil
    local lerpDay,lerpHour,lerpMin = 0,0,0
    lerpDay,lerpHour = DateTool.GetDay(lastTime)
    if lerpHour>0 then lerpHour,lerpMin = DateTool.GetHour(lerpHour)end
    if lerpMin >0 then lerpMin= DateTool.GetMinu(lastTime)end
    local endDay = begDay+lerpDay
    local endHour = h+lerpHour
    local endMin = m+lerpMin
    if tonumber(today)<endDay then 
        M.isOpen=true 
    elseif tonumber(today)==endDay then 
        if now.hour<endHour then M.isOpen=true 
        elseif now.hour==endHour then 
            if now.min<endMin then M.isOpen=true end
        end
    end
    if M.isOpen==true then
        seconds=DateTool.SecondsLerp(tonumber(today),now.hour,now.min,now.sec,endDay,endHour,endMin,0)
    else
        seconds=DateTool.SecondsLerp(tonumber(today),now.hour,now.min,now.sec,begDay,h,m,0)
    end
    M.timer:Stop()
    M.timer.seconds=seconds
    M.timer:Start()   
end

function M.CountTime()
    M.eTime(M.timer.remain)
end
function M.OpenArea()
    local isOpen = OpenMgr:IsOpen("710")
    if isOpen~=true then UITip.Log("秘境玩法系统暂未开启")return end
    --NW.ReqPosInfo()
    UIMgr.Open(UISecretArea.Name)
end

function M.WritePlunderRed()
    local pluNum=tostring(TableTool.GetDicCount(M.PlunderHistory))
    local filePath = string.format( "%s/%s.txt",UnityEngine.Application.persistentDataPath,User.instance.MapData.UID)
    local file = System.IO.File
    file.WriteAllText(filePath,pluNum)
end

function M.ReadPlunderRed()
    local filePath = string.format( "%s/%s.txt",UnityEngine.Application.persistentDataPath,User.instance.MapData.UID)
    local file = System.IO.File
	local isExit = file.Exists(filePath)
    if isExit==false then return end
    local str = file.ReadAllText(filePath)
    if StrTool.IsNullOrEmpty(str) then str=0 end
    local pluNum=TableTool.GetDicCount(M.PlunderHistory)
    M.IsPlunderRed=pluNum>tonumber(str)
end

function M.Clear(isconnect)
    if isconnect then return end
    TableTool.ClearDic(M.Origin)
    TableTool.ClearToPool(M.NightRoundDic)
    TableTool.ClearToPool(M.LatticeDic)
    ListTool.ClearToPool(M.GoodsList)
    TableTool.ClearDic(M.PlunderHistory)
    M.timer:Stop()
end


return M