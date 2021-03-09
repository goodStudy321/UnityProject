--[[
VIP管理类
--]]
VIPMgr={Name = "VIPMgr"}
local My=VIPMgr

My.eVIPTime=Event()
My.eVIPTime2=Event()
My.eVIPEnd=Event()
My.eVIPStart=Event()
My.eExp=Event()
My.eVIPLv=Event()
My.eGift=Event()
My.eVIPStoreRed=Event()
My.eBuy=Event()
My.eUpInfo=Event()
My.eUpAction =Event()
My.eCloseV4 = Event()

My.eUpTimer = Event()
My.eEndTimer = Event()
My.eOpenV4Icon = Event()
My.V4State = false

My.giftDic={}
My.firstBuy={}
My.timer=ObjPool.Get(DateTimer)
My.timer2=ObjPool.Get(DateTimer)
--红点状态字典(key值为tog值)
My.stateDic = {}
--默认显示的红点字典
My.norDic = {}

--// LY add begin
--// 当前是否自动使用小飞鞋
My.useFlyShoe = false;
--// LY add end

local overTime = false --vip过期
My.VipsRed = nil --VIP商城红点


--初始值
My.vipLv=0
My.time=0
My.exp=0
My.isExpire=false
My.canWeek=false
--end

function My.Init()
	GetError = ErrorCodeMgr.GetError
	My.InitNorDic()
	My.AddLnsr()

	My:CreateTimer()

	My.useFlyShoe = false;
end

--添加事件
function My.AddLnsr()
	local Add = ProtoLsnr.Add
	Add(21500, My.ResqInfo)
	Add(21502, My.ResqChange)
	Add(21504,My.ResqBuy)
	Add(21506,My.ResqGift)
	Add(21508,My.ResqWeek)
	Add(21510,My.ResqVIPDirect)

	RoleAssets.eUpAsset:Add(My.OnUpAsset)
	PropMgr.eRemove:Add(My.OnRemoveCard)
	PropMgr.eAdd:Add(My.OnAddCard)
	PropMgr.eUpNum:Add(My.OnUpNumCard)
end

--vip信息推送
function My.ResqInfo(msg)
	--vip过期时间
	My.time=msg.expire_time

	--vip等级
	My.vipLv=msg.level

	--vip经验
	My.exp=msg.exp

	--是否为VIP体验
	My.isExpire = msg.is_vip_experience

	--领取的VIP等级列表
	local dic=msg.gift_list
	if(dic~=nil)then
		My.SetGift(dic)
	end

	--初次购买列表(卡id)
	TableTool.ClearDic(My.firstBuy)
	local buy=msg.first_buy_list
	if buy then
		for i,v in ipairs(buy) do
			My.firstBuy[tostring(v)]=true
		end
	end

	--是否可领日福利
	My.canWeek=msg.day_gift_status

	--是否弹出VIP续费界面
	local isremaind = msg.is_remind
	if isremaind ==true then My.OpenVIPTip() end

	local remindTimeV4 = msg.v4_remind_time
	local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
	My.endTimeV4 = remindTimeV4 - sTime
	My:SetV4Btn()

	My.CountTime()
	My.eUpInfo()
	My.VIPStoreRed()
	if My.vipLv < 4 then
		My.ShowV4Red(true)
	else
		My.ShowV4Red(false)
	end
end

--vip信息改变同送 key等级 val经验
function My.ResqChange(msg)
	local list=msg.kv_list
	for i,v in ipairs(list) do
		if(v.id==1)then --等级
			My.vipLv=v.val
			My.eVIPLv()
			My.VIPStoreRed()
		elseif(v.id==2)then --经验
			My.exp=v.val
			My.eExp()
		end
	end
	My:SetV4Btn()
end

function My.ReqBuy(id)
	local msg=ProtoPool.GetByID(21503)
	msg.id=id
	ProtoMgr.Send(msg)
end

--vip卡购买返回
function My.ResqBuy(msg)
	local err = msg.err_code
	if(err==0)then
		My.time=msg.expire_time
		My.isExpire = msg.is_vip_experience
		local id=tostring(msg.first_buy)
		local tp = msg.type
		if tp==1 then
			UITip.Log("购买成功")
		else
			UITip.Log("使用成功")
		end
		My.firstBuy[id]=true
		My.CountTime()
	
		My.eBuy(id)
		My.eCloseV4()
	else
		UITip.Log(GetError(err))
	end
end

function My.ReqGift(lv)
	local msg=ProtoPool.GetByID(21505)
	msg.level=lv
	ProtoMgr.Send(msg)
end

--获取可以购买副本进入次数
function My.CopyEnter(t, lv)
	local temp = VIPLv[lv+1]
	if temp then
		if t == CopyType.Exp then
			return temp.arg6
		elseif t == CopyType.Glod then
			return temp.arg7
		elseif t == CopyType.SingleTD then
			return temp.arg8
		elseif t == CopyType.XH then
			return temp.arg9
		elseif t == CopyType.ZLT then
			return temp.arg11
		elseif t == CopyType.ZHTower then
			return temp.arg12
		end
	end
	return 0
end

--下一个可以购买副本进入次数和需要的vip等级
function My.NextCopyEnter(copyType)
	local vipLv = My.vipLv
	local temp = VIPLv[vipLv+1]
	local lv = nil
	local nNum = nil
	local key = nil
	if copyType == CopyType.Exp then
		key ="arg6"
	elseif copyType == CopyType.Glod then
		key ="arg7"
	elseif copyType == CopyType.SingleTD then
		key ="arg8"
	elseif copyType == CopyType.XH then
		key ="arg9"
	elseif copyType == CopyType.ZLT then
		key ="arg11"
	elseif copyType == CopyType.ZHTower then
		key = "arg12" 
	end
	if key then
		local cNum = temp and temp[key] or 0
		for i=1,#VIPLv do
			local v = VIPLv[i]
			local num = v[key]
			if num and tonumber(num) > tonumber(cNum) then
				lv = v.lv
				nNum = num
				break
			end
		end
	end
	return lv, nNum
end

--获取VIP等级（过期为0）
function My.GetVIPLv()
	if overTime==true then
		return 0
	else
		return My.vipLv
	end
end

--获取VIP表
function My.GetVIPInfo(vip)
	if not vip then vip=My.GetVIPLv() end
	local lv=VIPLv[vip+1]
	if not lv then return nil end
	return lv
end

--获取VIP等级礼物返回
function My.ResqGift(msg)
	local err = msg.err_code
	if(err==0)then
		local list = msg.gift_list
		if list then
			My.SetGift(list)
			My.eGift()
		end
		My.VIPStoreRed()
		UITip.Log("你已成功购买等级礼包")
	else
		UITip.Log(GetError(err))
	end
end

--领取日礼包
function My.ReqWeek()
	local msg = ProtoPool.GetByID(21507)
	ProtoMgr.Send(msg)
end

function My.ResqWeek(msg)
	local err = msg.err_code
	if(err==0)then
		My.canWeek=false
		My.VIPStoreRed()
		UITip.Log("你已成功领取日礼包")  		
	else
		UITip.Log(GetError(err))
	end
end

--直升V4
function My.ReqVIPDirect()
	local msg = ProtoPool.GetByID(21509)
	ProtoMgr.Send(msg)
end

function My.ResqVIPDirect(msg)
	local err = msg.err_code
	if(err==0)then
		UITip.Log("你已成功升级V4")
		My.OpenVIP()
	else
		UITip.Log(GetError(err))
	end
end

function My.SetGift(list)
	TableTool.ClearDic(My.giftDic)
	for i,v in ipairs(list) do
		My.giftDic[tostring(v)]=true
	end
	--My.LvGiftRed()
end

-- 显示V4按钮红点
function My.ShowV4Red(isShow)
	local actId = ActivityMgr.Jump
    if isShow == true then
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end
end

--等级礼包红点
function My.LvGiftRed()
	local lv = My.GetVIPLv()
	if lv==0 then return end
	local state = My.giftDic[tostring(lv)] or false
	local actId = ActivityMgr.VIPSC
    if state == false then
        SystemMgr:ShowActivity(actId,3)
    else
        SystemMgr:HideActivity(actId,3)
    end

	
end

function My.CountTime()
	--if(My.time~=0)then
		My.timer:Stop()
		local now=TimeTool.GetServerTimeNow()*0.001
		local lerp=My.time-now
		if lerp<=0 then 
			My.CountTimeNo()
			My.eVIPEnd() 
			My.timer.remain="" 
			overTime=true
		else		
			My.timer.seconds=lerp
			My.timer.invlCb:Add(My.Cb)
			My.timer.complete:Add(My.Complete)
			My.timer:Start()
			overTime=false
			My.eVIPStart()
		end
		My.eVIPTime()
	--end
end

--特惠倒计时
function My.CountTimeNo()
	My.timer2:Stop()
	My.timer2.seconds=604800
	My.timer2.invlCb:Add(My.CB2)
	My.timer2:Start()
	My.eVIPTime2()
end

function My.CB2()
	My.eVIPTime2()
end

--更新红点
function My.UpRedDot()
	if My.IsShow(My.stateDic) then return end
	if My.IsShow(My.norDic) then return end
	My.ChangeRedDot(false)
end

--判断是否显示红点
function My.IsShow(dic)
	for k,v in pairs(dic) do
		if v then
			My.ChangeRedDot(true)
			return true
		end
	end
end

--更新红点（外部调用）
function My.UpAction(k,v)
	local key = tostring(k)
	if type(key) ~= "string" or type(v) ~= "boolean" then
		iTrace.Error("传入的参数错误")
		return
	end
	if My:IsShieldBtn(k) then return end
	My.stateDic[key] = v
	My.UpRedDot()
	My.eUpAction()
end

--改变红点状态
function My.ChangeRedDot(state)
	local ui = UIMgr.Get(UIMainMenu.Name)
	if ui then
		ui:SetRedDot(state)
	else
		iTrace.Log("SJ", "主界面已被关闭")
	end
end

--获取屏蔽状态
function My:IsShieldBtn(id)
	local index = 0
	local btnId = tonumber(id)
	if btnId == 1 then
		index = ShieldEnum.Recharge--充值
		if ShieldEntry.IsShield(index) then
			My.norDic["1"] = false
		end
	elseif btnId == 2 then
		index = ShieldEnum.MonthCard--超值月卡
		if ShieldEntry.IsShield(index) then
			My.norDic["2"] = false
		end
	elseif btnId == 3 then
		index = ShieldEnum.InvestFinance--投资理财
		if ShieldEntry.IsShield(index) then
			My.norDic["3"] = false
		end
	elseif btnId == 4 then
		--开服累充
	elseif btnId == 5 then
		index = ShieldEnum.VIPPower--VIP特权
	elseif btnId == 6 then
		index = ShieldEnum.VIPInvest--VIP投资
	end
	return ShieldEntry.IsShield(index)
end

--VIP红点
-- function My.VIP()
-- 	local state = false
-- 	local viplv= My.vipLv
-- 	if viplv~=0 and not My.isExpire then 
-- 		local dic = My.giftDic
-- 		for i=1,viplv do
-- 			if not dic[tostring(i)] then state=true  break end
-- 		end
-- 	else
-- 		state=false
-- 	end	
-- 	My.UpAction(6,state)
-- end

function My:SetV4Btn()
	local vip = My.GetVIPLv()
	local time = My.endTimeV4
	if vip < 4 then
		My.V4State = true
		My.eOpenV4Icon(My.V4State)
		My:UpTimer(time)
	else
		My:EndCountDown()
	end
end

function My:UpTimer(rTime)
	local timer = My.timer3
	timer:Stop()
	timer.seconds = rTime
	if rTime == nil then return end
	timer:Start()
	local day,remain = DateTool.GetDay(rTime)
	local hour,remain = DateTool.GetHour(rTime)
	self:InvCountDown()
end

--创建V4按钮显示计时器
function My:CreateTimer()
    if My.timer3 then return end
    My.timer3 = ObjPool.Get(DateTimer)
    local timer = My.timer3
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
	local time = My.timer3.remain
	local allRemain = My.timer3:GetRestTime()
	local day,remain = DateTool.GetDay(allRemain)
	local hour = DateTool.GetHour(remain)
	local oneDay = 86400
	if allRemain < oneDay then
		My.timer3.fmtOp = 3
	else
		time = day.."天"..hour.."小时"
	end
	My.eUpTimer(time, allRemain)
end

--结束倒计时
function My:EndCountDown()
	My.timer3:Stop()
	My.V4State = false
	My.eOpenV4Icon(My.V4State)
	My.eEndTimer()
end

function My.OnUpAsset(id)
	if id ~=2 then return end
	My.VIPStoreRed()
end

--VIP商城红点
function My.VIPStoreRed()
	if My.VipsRed==nil then 
		My.VipsRed={}
		My.VipsRed["3"]=false
		My.VipsRed["4"]=false
		My.VipsRed["5"]={}
	end

	if My.GetVIPLv()==0 then 
		My.VipsRed["3"]=false
		My.VipsRed["4"]=false
		TableTool.ClearDic(My.VipsRed["5"])
		return 
	else
		My.VipsRed["3"]=My.canWeek
	end

	local lv = My.GetVIPLv()+1
	if lv~=0 then 
		My.VipsRed["4"]=false
		local dic = My.VipsRed["5"]
		for i=2,lv do
			local state = My.giftDic[tostring(i-1)] or false
			local vip = VIPLv[i]
			if not vip then iTrace.eError("xioayu","vip表为空 id: "..i) return end
			local price = vip.Price
			local isenough = RoleAssets.IsEnoughAsset(2,tonumber(price))
			local st = true 
			if state==true or isenough==false then --不能再领取
				st=false
			end
			dic[i-1]=st
			if st==true then My.VipsRed["4"]=true end
		end
	end

	My.eVIPStoreRed()

	-- local state1= My.VipsRed["3"]
	-- local state2 = My.VipsRed["4"]
	-- local actId = ActivityMgr.VIPSC
	-- if state1==true or state2==true then
	-- 	SystemMgr:ShowActivity(actId,3) --红点		
	-- else
	-- 	SystemMgr:HideActivity(actId,3)
	-- end

	local state1= My.VipsRed["3"]
	local state2 = My.VipsRed["4"]
	local actId = ActivityMgr.VIPSC
	-- if state1==true then    --暂时屏蔽因为屏蔽了福利专区
	-- 	SystemMgr:ShowActivity(actId,3) --红点		
	-- elseif state1==false then 
	-- 	SystemMgr:HideActivity(actId,3)
	-- end
	if state2==true then
		SystemMgr:ShowActivity(actId,4) --红点		
	elseif state2==false then 
		SystemMgr:HideActivity(actId,4)
	end

	local card = My.GetVIPLv()>0 and #PropMgr.GetItemsByUseEff(91)>0
	My.UpAction(6,state2==true or card==true)
end

function My.OnRemoveCard(id,tp,type_id)
	if tp~=1 then return end
	local item = UIMisc.FindCreate(type_id)
	if item.uFx==91 then
		My.VIPStoreRed()
	end
end

function My.OnAddCard(tb,action,tp)
	if tp~=1 then return end
	local item = UIMisc.FindCreate(tb.type_id)
	if item.uFx==91 then
		My.VIPStoreRed()
	end
end

function My.OnUpNumCard(tb,tp,num)
	if tp~=1 then return end
	local item = UIMisc.FindCreate(tb.type_id)
	if item.uFx==91 then
		My.VIPStoreRed()
	end
end

--初始化默认显示的红点
function My.InitNorDic()
	local list = {1, 2, 3, 8}
	-- local list = {2, 3}--屏蔽充值
	for i,v in ipairs(list) do
		local key = tostring(v)
		My.norDic[key] = true
	end
end


function My.Cb()
	My.eVIPTime()
end

function My.Complete()
	My.CountTimeNo()
	My.eVIPEnd()
	overTime=true
end

local mTp = nil
local mIsVIPCard = nil
function My.OpenVIP(tp,isVIPCard)
	if isVIPCard==true and VIPMgr.GetVIPLv()==0 then
		UITip.Log("VIP0不可使用VIP经验卡")
		return 
	end
	if My:IsShieldBtn(tp) then
		UITip.Log("该功能尚未开放")
		return
	end

	if not tp then tp=6 end
	mTp=tp
	mIsVIPCard=isVIPCard
	local ui = UIMgr.Get(UIVIP.Name)
	if ui then
		ui:SwitchTg(mTp,mIsVIPCard)
	else
		UIMgr.Open(UIVIP.Name,My.VIPCb)
	end	
end

function My.VIPCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:SwitchTg(mTp,mIsVIPCard)
	end
end

--获取决斗场vip限制等级
function My.GetVipSkip()
	local lv = 0
	for i = 1,#VIPLv do
		local cfg = VIPLv[i]
		if cfg.skipDroiyan >= 1 then
			lv = cfg.lv
			break
		end
	end
	return lv
end

--打开VIP提示续费界面
function My.OpenVIPTip()
	UIMgr.Open(UIVIPTip.Name)
end

function My.Clear()
	My.useFlyShoe = false;
	My.V4State = false
	
	overTime=false
	My.timer:Stop()
	if My.timer3 then
		My.timer3:Stop()
	end
	TableTool.ClearDic(My.giftDic)
	TableTool.ClearDic(My.stateDic)
	My.ChangeRedDot(false)
end

return My