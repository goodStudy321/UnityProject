
--[[
    新增精灵管理类
--]]
ElvesNewMgr = {Name = "ElvesNewMgr"}

local My = ElvesNewMgr
My.State = true
My.PayState = nil
local Send = ProtoMgr.Send
--主界按钮状态
My.eUpState = Event()

--界面内按钮状态
My.eElvesBtnState = Event()
--主界面倒计时
My.eUpTimer = Event()
My.eEndTimer = Event()

function My:Init()
    --创建计时器
    self:CreateTimer()
    self:SetLnsr("Add")
    self:AddProto()
end

function My:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

function My:ProtoHandler(Lsnr)
    Lsnr(26128, self.RespElvesInfo, self)
    Lsnr(26132, self.RespGetElves, self)
end

function My:RespElvesInfo(msg)
    local buyPrice = msg.money
    local buyS = msg.type
    self.PayState = buyS
    self.State = true
    self.buyMoney = buyPrice
    self:RespUpActivState()
    self.eElvesBtnState()
    SystemMgr:ShowActivity(ActivityMgr.YJJBSH)
end

--领取返回
function My:RespGetElves(msg)
    local err = msg.err_code
	if not self:CheckErr(err) then return end
    self.State = false
    self.PayState = 2
    self.eUpState()
    self.eElvesBtnState()
    
    local mgr = ActivityMgr
	local k,v = mgr:Find(mgr.YJJBSH)
	mgr:Remove(v)
end

--领取
function My:ReqGetElves()
	local msg = ProtoPool.GetByID(26131)
	Send(msg)
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Error(err)
	    return false
    end
    return true
end


--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown,self)
    timer.complete:Add(self.EndCountDown,self)
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    time = math.floor(time)
    self.eUpTimer(time)
end

--结束倒计时
function My:EndCountDown()
    self.State = false
    self.timer:Stop()
    self.timer = nil
    self.eEndTimer()
end


--设置监听
function My:SetLnsr(func)
    ActivStateMgr.eUpActivState[func](ActivStateMgr.eUpActivState, self.RespUpActivState, self)
    FestivalActMgr.eUpdateActState[func](FestivalActMgr.eUpdateActState, self.RespUpActivState, self)
end

function My:RespUpActivState()
    self.State = true
    local money = self.buyMoney
    local type = self.PayState -- 0 未买  1 已买  2 已领
    if type == 2 or type == nil then
        self.State = false
        self.eUpState(false)
        return
    end
    local isOpen = LivenessInfo:GetActInfoById(1030)
    if isOpen == nil then
        self.State = false
        self.eUpState(false)
        return
    end
    local info = nil
    if money > 0 then
        info = FestivalActMgr:GetActInfo(FestivalActMgr.SHJL)
    elseif money == 0 then
        info = LivenessInfo.xsActivInfo["1030"]
    end
    if not info then 
        self.State = false
        self.eUpState(false)
        return
    end
    local nowTime = TimeTool.GetServerTimeNow()*0.001
    local endTime = info.eTime
    if nowTime > endTime then
        self.State = false
        self.eUpState(false)
        return
    end
    self.State = true
    self.eUpState(true)
    local leftTime = endTime - nowTime
    self.timer:Restart(leftTime, 1)
end

--清理缓存
function My:Clear()
    self.State = nil
    self.PayState = nil
    --停止计时器
    if self.timer then self.timer:Stop() end
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    self:RemoveProto()
    -- euiclose:Remove(self.CloseUI,self);
end

return My