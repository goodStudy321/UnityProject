--[[
 	authors 	:Liu
 	date    	:2018-12-7 9:40:00
 	descrition 	:结婚管理类
--]]

MarryMgr = {Name = "MarryMgr"}

local My = MarryMgr

local Info = require("Marry/MarryInfo")

My.actionDic = {}
My.eChangeMarry = Event()
My.eUpActionState =Event()

function My:Init()
    Info:Init()
    self.IsPSucc = false--判断是否提亲成功
    self.State = false
    self.eShowPop = Event()
    self.ePropose = Event()
    self.eMarry = Event()
    self.eDivorce = Event()
    self.eUpTimer = Event()
    self.eEndTimer = Event()
    self.eAppointInfo = Event()
    self.eAppoint = Event()
    self.eAddGuest = Event()
    self.eInviteGuest = Event()
    self.eFeastState = Event()
    self.eApplyGuest = Event()
    self.eReplyGuest = Event()
    self.eBuyJoin = Event()
    self.eGivenTime = Event()
    self.eGivenSucc = Event()
    --结婚副本
    self.eExp = Event()
    self.eHeat = Event()
    self.eHeatShow = Event()
    self.eMapInfo = Event()
    self.eWishLog = Event()
    self.eTaset = Event()
    self.eCandyTime = Event()
    self.eUpCandyCount = Event()
    self.eFireworks = Event()
    --弹窗
    self.ePopClick = Event()
    self.ePopCancel = Event()
    self.eUpAction = Event()

    self:Reset()

    self:SetLnsr(ProtoLsnr.Add)
    self:CreateTimer()
    EventMgr.Add("AllAnimFinish",EventHandler(self.AnimFinish,self))
end

function My:Reset()
    self.RoleLoginDay = 0
    self.CountDownNum = 0
end

--设置监听
function My:SetLnsr(func)
    func(23602, self.RespMarryInfo, self)
    func(23604, self.RespDivorce, self)
    func(23606, self.RespCoupleInfo, self)
    func(23608, self.RespTitleInfo, self)
    func(23612, self.RespPropose, self)
    func(23614, self.RespProposeReply, self)
    func(23616, self.RespProposeSucc, self)
    func(23668, self.RespFeastState, self)
    func(23670, self.RespFeastInfo, self)
    func(23672, self.RespAppointInfo, self)
    func(23674, self.RespAppoint, self)
    func(23676, self.RespInviteGuest, self)
    func(23678, self.RespAddGuest, self)
    func(23680, self.RespApplyGuest, self)
    func(23682, self.RespReplyGuest, self)
    func(23684, self.RespSetBuy, self)
    func(23686, self.RespBuyJoin, self)
    --结婚副本
    func(23700, self.RespMarryMapInfo, self)
    func(23702, self.RespMarryMapExp, self)
    func(23704, self.RespTasteCount, self)
    func(23706, self.RespUpHeat, self)
    func(23708, self.RespUpCollect, self)
    func(23710, self.RespPickCount, self)
    func(23712, self.RespCandyTime, self)
    func(23714, self.RespHeatState, self)
    func(23720, self.RespWishLog, self)
    func(23722, self.RespWish, self)
    func(23724, self.RespFireworks, self)

    func(23730, self.RespGiven, self)
    SceneMgr.eChangeEndEvent:Add(self.ChangeSceneEnd, self)
end

--响应结婚信息
function My:RespMarryInfo(msg)
    local treeEndTime = msg.tree_end_time
    local treeIsAward = msg.tree_active_reward
    local treeDailyTime = msg.tree_daily_time
    local coupleTreeEndTime = msg.couple_tree_end_time
    local knotid = msg.knot_id
    local knotExp = msg.knot_exp
    local coupleid = tonumber(msg.couple_id)
    local coupleidStr = tostring(msg.couple_id)
    local marryTime = msg.marry_time
    Info:SetData(treeEndTime, treeIsAward, treeDailyTime, coupleTreeEndTime, knotid, knotExp, coupleid, marryTime,coupleidStr)
    if coupleid > 0 then
        self:ReqCoupleInfo()
        MarriageTreeMgr:InitAct()
        MarriageTreeMgr:SetActive()
    end
    KnotMgr.UpRed()
end

--请求提亲
function My:ReqPropose(id, proposeType)
    local msg = ProtoPool.GetByID(23611)
    msg.propose_id = id
    msg.type = proposeType
    ProtoMgr.Send(msg)
end

--响应提亲
function My:RespPropose(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local id = msg.from_role_id
    local name = msg.from_role_name
    local proposeType = msg.type
    local time = msg.propose_end_time
    if id ~= User.MapData.UIDStr then
        Info:SetProposeData(id, name, proposeType, time)
        self.eShowPop(id)
        self:UpTimer()
        self:OpenPop()
    else
        self.ePropose()
    end
end

--打开提亲回复弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIProposePop.Name)
    if ui then
        ui:Close()
    end
    UIProposePop:OpenTab(1)
end

--请求提亲回复
function My:ReqProposeReply(id, answer)
    local msg = ProtoPool.GetByID(23613)
    msg.to_propose_id = id
    msg.answer_type = answer
	ProtoMgr.Send(msg)
end

--响应提亲回复
function My:RespProposeReply(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local isMarry = msg.answer_type
    self:ResetTimer()
end

--响应提亲成功
function My:RespProposeSucc(msg)
    local id = tonumber(msg.couple_id)
    local name = msg.couple_name
    local type = msg.type
    local count = msg.feast_times
    local marryTime = msg.marry_time
    self.IsPSucc = true
    Info.data.coupleid = id
    Info.data.coupleidStr = tostring(msg.couple_id)
    Info.data.count = count
    Info.data.marryTime = marryTime
    Info:ClearPList()
    self:ResetTimer()
    self:ReqCoupleInfo()
    self.eMarry()
end

--请求离婚
function My:ReqDivorce()
    local msg = ProtoPool.GetByID(23603)
    ProtoMgr.Send(msg)
end

--响应离婚
function My:RespDivorce(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    Info:ClearCoupleData()
    self.eDivorce()
end

--请求仙侣信息
function My:ReqCoupleInfo()
    local msg = ProtoPool.GetByID(23605)
    ProtoMgr.Send(msg)
end

--响应仙侣信息
function My:RespCoupleInfo(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    self.cInfo = {}
	local info = self.cInfo
	info.id = msg.role_id
	info.name = msg.role_name
    info.lv = msg.level
    info.vip = msg.vip_level
    info.sex = msg.sex
    info.category = msg.category
    info.skins = {}
    local skinList = msg.skin_list
	local len = #skinList
	for i=1, len do
		table.insert(info.skins, skinList[i])
    end
    Info.data.coupleInfo = info
    if self.IsPSucc then
        UIProposePop:OpenTab(2)
        self.IsPSucc = false
    end
    self:GiveInfo()
end

--响应称号信息
function My:RespTitleInfo(msg)
    local id = msg.marry_title_ids
    Info.data.titleId = id
    -- iTrace.Error("id = "..id)
end

--响应婚宴信息
function My:RespFeastInfo(msg)
    Info:InitFeastData()

    local time = msg.feast_start_time
    local count = msg.feast_times
    local guestNum = msg.extra_guest_num
    local isBuyJoin = msg.is_buy_join
    local guestList = msg.guest_list
    local applyList = msg.apply_guest_list
    Info.data.count = count
    Info.feastData.feastTime = time
    Info.feastData.guestNum = guestNum
    Info.feastData.isBuyJoin = isBuyJoin
    for i,v in ipairs(guestList) do
        Info:SetGuestList(v.id, v.val)
    end
    for i,v in ipairs(applyList) do
        -- iTrace.Error("idid = "..v.id.." valval = "..v.val)
        Info:SetApplyGuestList(v.id, v.val)
        self:SetAction(true)
        self.eUpAction()
    end

    -- iTrace.Error("time = "..time.." count = "..count.." guestNum = "..guestNum.." len = "..#guestList)
end

--请求预约场次信息
function My:ReqAppointInfo()
    local msg = ProtoPool.GetByID(23671)
    ProtoMgr.Send(msg)
end

--响应预约场次信息
function My:RespAppointInfo(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local hourList = msg.hour_list
    if #hourList < 1 then
        Info:ClearHourList()
    end
    for i,v in ipairs(hourList) do
        local key = tostring(v)
        Info.feastData.hourDic[key] = true
    end
    self.eAppointInfo()
end

--请求预约场次
function My:ReqAppoint(hour)
    local msg = ProtoPool.GetByID(23673)
    msg.hour = hour
    -- iTrace.Error("hour = "..hour)
    ProtoMgr.Send(msg)
end

--响应预约场次
function My:RespAppoint(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local time = msg.feast_start_time
    local count = msg.feast_times
    Info.feastData.feastTime = time
    Info.data.count = count
    if time > 0 then
        local hour = Info:GetDate(time, "HH")
        if hour == 0 then hour = 24 end
        local key = tostring(hour)
        Info.feastData.hourDic[key] = true
        Info:ClearGuestList()
    end
    self.eAppoint()
end

--请求邀请宾客
function My:ReqInviteGuest(id)
    local msg = ProtoPool.GetByID(23675)
    msg.role_id = id
    ProtoMgr.Send(msg)
end

--响应邀请宾客
function My:RespInviteGuest(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    Info:SetGuestList(msg.guest.id, msg.guest.val)
    self.eInviteGuest(msg.guest)
end

--请求增加宾客上限
function My:ReqAddGuest(num)
    local msg = ProtoPool.GetByID(23677)
    msg.add_num = num
    ProtoMgr.Send(msg)
end

--响应增加宾客上限
function My:RespAddGuest(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local guestNum = msg.extra_guest_num
    Info.feastData.guestNum = guestNum
    self.eAddGuest()
end

--响应婚宴状态信息
function My:RespFeastState(msg)
    Info.feastData.feastState = msg.status
    Info.feastData.endTime = msg.end_time
    --举办婚礼角色1
    self.role1 = {}
	local info1 = self.role1
    info1.id = msg.feast_role1.role_id
    info1.name = msg.feast_role1.role_name
    info1.category = msg.feast_role1.category
    info1.sex = msg.feast_role1.sex
    Info.feastData.role1 = info1
    --举办婚礼角色2
    self.role2 = {}
    local info2 = self.role2
    info2.id = msg.feast_role2.role_id
    info2.name = msg.feast_role2.role_name
    info2.category = msg.feast_role2.category
    info2.sex = msg.feast_role2.sex
    Info.feastData.role2 = info2
    if msg.status == 0 then
        self.State = false
        Info:ClearFeastRole()
    elseif msg.status == 1 or msg.status == 2 then
        self.State = true
    end
    self.eFeastState(self.State)
    -- iTrace.Error("name = "..msg.status.." time = "..tostring(msg.end_time))
end

--请求婚宴请帖
function My:ReqApplyGuest()
    local msg = ProtoPool.GetByID(23679)
    ProtoMgr.Send(msg)
end

--响应婚宴请帖
function My:RespApplyGuest(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local id = tonumber(msg.guest.id)
    Info:SetApplyGuestList(id, msg.guest.val)
    self.eApplyGuest()
    --红点
    if id ~= tonumber(User.MapData.UIDStr) then
        local state = Info:IsExistTpply()
        self:SetAction(state)
        self.eUpAction()
    end
end

--请求婚宴请帖答复
function My:ReqReplyGuest(type, list)
    local msg = ProtoPool.GetByID(23681)
    msg.op_type = type
    for i,v in ipairs(list) do
        msg.role_ids:append(v)
    end
    ProtoMgr.Send(msg)
end

--响应婚宴请帖答复
function My:RespReplyGuest(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    if msg.op_type == 0 then--拒绝
        for i,v in ipairs(msg.roles) do
            Info:RemoveAGList(v.id)
        end
    elseif msg.op_type == 1 then--同意
        for i,v in ipairs(msg.roles) do
            Info:RemoveAGList(v.id)
            Info:SetGuestList(v.id, v.val)
        end
    end
    self.eReplyGuest(msg.op_type)
    --红点
    local state = Info:IsExistTpply()
    self:SetAction(state)
    self.eUpAction()
end

--请求设置购买请帖
function My:ReqSetBuy(isJoin)
    local msg = ProtoPool.GetByID(23683)
    msg.is_buy_join = isJoin
    ProtoMgr.Send(msg)
end

--响应设置购买
function My:RespSetBuy(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local isBuyJoin = msg.is_buy_join
    Info.feastData.isBuyJoin = isBuyJoin
    self.eBuyJoin()
end

--请求购买成为宾客
function My:ReqBuyJoin()
    local msg = ProtoPool.GetByID(23685)
    ProtoMgr.Send(msg)
end

--响应购买成为宾客
function My:RespBuyJoin(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    local id = tonumber(msg.guest.id)
    local val = msg.guest.val
    Info:SetGuestList(id, val)
    Info:RemoveAGList(id)
    self.eInviteGuest(msg.guest)
    self.eReplyGuest(0)
    --红点
    if id ~= tonumber(User.MapData.UIDStr) then
        local state = Info:IsExistTpply()
        self:SetAction(state)
        self.eUpAction()
    end
end

--==========================================================================================结婚副本

--响应结婚副本信息
function My:RespMarryMapInfo(msg)
    Info:InitMapData()
    Info.isAnim = false

    local bowSTime = msg.bow_time
    local bowETime = msg.end_time
    local candyTime = msg.collect_time
    local tasetCount = msg.taste_times
    local heat = msg.heat
    local remainCount = msg.remain_times
    local pickCount = msg.pick_times
    Info:SetMapData(bowSTime, bowETime, candyTime, tasetCount, heat, remainCount, pickCount)
    local list = Info.mapData.wishInfoList
    for i,v in ipairs(msg.wish_logs) do
        self.wishInfo = {}
        local info = self.wishInfo
        info.id = v.role_id
        info.name = v.role_name
        info.time = v.wish_time
        info.toId = v.to_role_id
        info.toName = v.to_role_name
        info.index = v.index_id
        table.insert(list, info)
    end
    self.eMapInfo()

    -- UIMgr.Open(UIMarryCopy.Name)
    -- iTrace.Error("bowSTime ="..bowSTime.." bowETime = "..bowETime.." heat = "..heat)
end

--响应结婚副本经验
function My:RespMarryMapExp(msg)
    local exp = msg.exp
    self.eExp(exp)
end

--响应品尝次数
function My:RespTasteCount(msg)
    local tasetCount = msg.taste_times
    Info.mapData.tasetCount = tasetCount
    self.eTaset()
    -- iTrace.Error("RespTasteCount = "..tasetCount)--------
end

--响应天降喜糖采集结束时间
function My:RespCandyTime(msg)
    local candyTime = msg.collect_time
    Info.mapData.candyTime = candyTime
    self.eCandyTime()
end

--热度状态
function My:RespHeatState(msg)
    local heat = msg.heat
    self.eHeatShow(heat)
end

--响应更新热度
function My:RespUpHeat(msg)
    local heat = msg.heat
    self.eHeat(heat)
end

--响应更新采集次数
function My:RespUpCollect(msg)
    local count = msg.remain_times
    Info.mapData.remainCount = count
    self.eUpCandyCount(count)
    -- iTrace.Error("RespUpCollect = "..count)--------
end

--响应剩余掉落物的可拾取次数
function My:RespPickCount(msg)
    local count = msg.pick_times
    -- iTrace.Error("pick = "..count)------------
end

--请求祝福
function My:ReqWish(type, id)
    local msg = ProtoPool.GetByID(23721)
    msg.index_id = type
    msg.to_role_id = id
    ProtoMgr.Send(msg)
end

--响应祝福
function My:RespWish(msg)
    local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    UITip.Log("祝福成功")
end

--响应祝福日志
function My:RespWishLog(msg)
    local list = Info.mapData.wishInfoList
    local v = msg.wish_log
    self.wishInfo = {}
    local info = self.wishInfo
    info.id = v.role_id
    info.name = v.role_name
    info.time = v.wish_time
    info.toId = v.to_role_id
    info.toName = v.to_role_name
    info.index = v.index_id
    table.insert(list, info)
    self.eWishLog()
end

--响应烟火
function My:RespFireworks(msg)
    self.eFireworks(msg.type_id)
end

--赠送返回
function My:RespGiven(msg)
    local err = msg.err_code
    if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    self.eGivenSucc()
    -- iTrace.eError("GS","赠送返回成功")
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--更新计时器
function My:UpTimer()
    local rTime = Info:GetNextPTime()
    if rTime > 0 then
        local timer = self.timer
        timer:Stop()
        timer.seconds = rTime
        timer:Start()
    end
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer.remain
    self.eUpTimer(time)
end

--结束倒计时
function My:EndCountDown()
    
end

--重置计时器状态
function My:ResetTimer()
    local len = Info:RemovePList()
    if len == 0 then
        self.eShowPop(-1)
    else
        self:UpTimer()
    end
    self.eEndTimer()
end

--前往结婚寻路结束
function My:NavPathEnd()
    if User.SceneId == Info.npcSId then
        local key = tostring(Info.npcId)
        local cfg = NPCTemp[key]
        if cfg == nil then return end
        local pPos = FindHelper.instance:GetOwnerPos()
        local pos = Vector3.New(cfg.pos.x*0.01, cfg.pos.y*0.01, cfg.pos.z*0.01)
        local dis = Vector3.Distance(pPos, pos)
        if dis < 2 then
            UIMarryInfo:OpenTab(4)
            EventMgr.Remove("NavPathComplete", EventHandler(self.NavPathEnd, self))
        end
    end
end

--响应切换场景结束
function My:ChangeSceneEnd()
    if User.SceneId == 30020 then
        local ui = UIMgr.Get(UIMarryCopy.Name)
        if ui then
            ui:Close()
        end
        UIMgr.Open(UIMarryAnim.Name)
    end
end

--设置管理宾客红点
function My:SetAction(isShow)
    local actId = ActivityMgr.JHQT
    if isShow then
        SystemMgr:ShowActivity(actId)
        Info.isShowAction = true
    else
        SystemMgr:HideActivity(actId)
        Info.isShowAction = false
    end
end

--设置红点（外部调用）
function My:SetActionDic(k,v)
	local key = tostring(k)
	if type(key) ~= "string" or type(v) ~= "boolean" then
		iTrace.Error("传入的参数错误")
		return
	end
    My.actionDic[key] = v
    self:UpActionDic()
    My.eUpActionState()
end

--更新红点字典
function My:UpActionDic()
    local isShow = false
    for k,v in pairs(My.actionDic) do
        if v then
            isShow = v
            break
        end
    end
    My.eChangeMarry(isShow)
end

--清理缓存
function My:Clear()
    self:GivenPoolDown()
    self:Reset()
    Info:Clear()
    if self.timer then self.timer:Stop() end
end

--监听动画播放结束
function My:AnimFinish()
    if User.SceneId == 30020 then
        SceneMgr:ReqPreEnter(30019, false, true)
        UIMgr.Open(UIMarryCopy.Name)
    end
end

function My:GiveInfo()
    local loginDay = self:GetLoginDay()
    self.RoleLoginDay = loginDay
    self:GivenCountdown()
    self:GetCountTime()
    local isMarry = Info:IsMarry()
    self:SetActionDic(5,isMarry)
end

--请求赠送
function My:ReqGiven(givenTab,givenText)
    local msg = ProtoPool.GetByID(23729)
    for i,v in ipairs(givenTab) do
        msg.goods_list:append(v.id)
        -- iTrace.eError("GS","send id== ",v.id,"   givenText== ",givenText)
	end
    msg.text = givenText
    ProtoMgr.Send(msg)
end


--获取结婚后12小时后的时间戳
function My:GetCountTime()
    local marryTime = Info.data.marryTime
    marryTime = marryTime or 0
    local needDay,needHour = self:GetGlobalData()
    -- local oneDayTime = (24*60*60)*needDay
    local oneDayTime = 0
    local oneHourTime = 60*60
    local needT = oneHourTime * needHour
    local endTime = 0
    if needHour > 0 then
        endTime = marryTime + needT + oneDayTime
    end
    return endTime
end

function My:GetGlobalData()
    local loginDay = self.RoleLoginDay
    local cfg = GlobalTemp["200"].Value1
    local id1 = cfg[1].id
    local val1 = cfg[1].value
    local id2 = cfg[2].id
    local val2 = cfg[2].value
    local needDay = 2
    local needHour = 0
    if loginDay <= id1 then
        needDay = id1
        needHour = val1
    elseif loginDay > id2 then
        needDay = id2
        needHour = val2
    end
    return needDay,needHour
end

function My:GivenCountdown()
    local endTime = 0
    local severTime = 0
    local seconds = 0
    endTime = self:GetCountTime()
    severTime = TimeTool.GetServerTimeNow()*0.001
    seconds = endTime - severTime
    local loginDay = self.RoleLoginDay
    local needDay = GlobalTemp["200"].Value1[2].id
    local marryTime = Info.data.marryTime
    -- iTrace.eError("GS","loginDay== ",loginDay,"   endTime== ",endTime,"   marryTime== ",marryTime)
    if seconds > 0 then
        if not self.givenTimer then
            self.givenTimer = ObjPool.Get(DateTimer)
            self.givenTimer.fmtOp = 0
            self.givenTimer.apdOp = 0
            self.givenTimer.invlCb:Add(self.GivenInvCountDown, self)
            self.givenTimer.complete:Add(self.GivenEndCountDown, self)
        end
        self.givenTimer.seconds = seconds
        self.givenTimer:Stop()
        self.givenTimer:Start()
        -- self:GivenInvCountDown()
    end
end

function My:GivenInvCountDown()
	local time = self.givenTimer:GetRestTime()
    time = DateTool.FmtSec(time,0,0,true)
    self.CountDownNum = time
    self.eGivenTime()
    -- self.timerLab.text = time
end

function My:GivenEndCountDown()
    if self.givenTimer then
        self.givenTimer:Stop()
        self.eGivenTime(true)
	end
end

function My:GivenPoolDown()
    if self.givenTimer then
        self.givenTimer:AutoToPool()
        self.givenTimer = nil
    end
end

function My:IsCanGiven()
    local isMarry = Info:IsMarry()
    local loginDay = self.RoleLoginDay
    if not isMarry then
        return false
    end
    local needDay = GlobalTemp["200"].Value1[1].id
    if loginDay <= needDay then
        return true
    end
    local seconds = self:GetCountTime() - (TimeTool.GetServerTimeNow()*0.001)
    if seconds <= 0 then
        return true
    end
    return false
end

function My:GetLoginDay()
    local user = User.instance
    local data = user.MapData
    local createTime = data.LstCreateTime
    local curtime = TimeTool.GetServerTimeNow();
    curtime = curtime * 0.001
    local day = DateTool.GetDay(curtime - createTime) + 1
    return day
end

--仙侣互赠装备数据
function My:GetGivenEquipData()
    local equipData = PropMgr.GetBagEquip()
    local tab = {}
    local len = #equipData
    for i = 1,len do
        local info = equipData[i]
        if not info.bind then
            table.insert(tab,info)
        end
    end
    table.sort(tab, function(a,b) return a.index < b.index end)
    return tab
end

--仙侣互赠天机印数据
function My:GetGivenSMSData()
    local smsData = PropMgr.tb5Dic
    local tab = {}
    for k,v in pairs(smsData) do
        if not v.bind then
            table.insert(tab,v)
        end
    end
    table.sort(tab, function(a,b) return SMSMgr:Sort(a,b) end)
    return tab
end

--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
    SceneMgr.eChangeEndEvent:Remove(self.ChangeSceneEnd, self)
    TableTool.ClearFieldsByName(self,"Event")
    EventMgr.Remove("AllAnimFinish",EventHandler(self.AnimFinish,self))
end

return My