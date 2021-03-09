
FirstPayMgr = {Name = "FirstPayMgr"}
local My = FirstPayMgr
local CheckErr = ProtoMgr.CheckErr

local Info = require("Data/OpenService/FirstPayInfo")

function My:Init()
    self.eFirstInfo = Event()
    self.eGetAward = Event()
    self.firstCPM = {}
    self.firstOpen = {}
    self.firstOpen[49] = nil
    self.firstOpen[50] = nil
    self.firstOpen[51] = nil
    self.CPMPa = nil
    self.isShow = false
    self.serverCharS = false
    self:AddProto()
    UserMgr.eLvEvent:Add(self.LvChange,self)
end

function My:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

--后台屏蔽功能状态
--屏蔽: true      开启: false
function My:IsCanShield()
    local id = ShieldEnum.FirstPay
    local isShield = ShieldEntry.IsShield(id)
    return isShield
end

function My:LvChange()
    if self.serverCharS == false then
        return
    end
    local isGet = self:IsPayState()
    if isGet == false and (self.firstOpen[49] == nil or self.firstOpen[50] == nil or self.firstOpen[51] == nil) then
        local roleLv = User.MapData.Level
        local oneLv = SystemOpenTemp["49"].trigParam
        local twoLv = SystemOpenTemp["50"].trigParam
        local threeLv = SystemOpenTemp["51"].trigParam
        if roleLv >= oneLv and self.firstOpen[49] == nil then
            self.firstOpen[49] = 1
            UIFirstCPM:OpenFirsyCPM()
            self:OpenLvUI(49)
        elseif roleLv >= twoLv and self.firstOpen[50] == nil then
            self.firstOpen[50] = 1
            UIFirstPay:OpenFirsyPay()
            self:OpenLvUI(50)
        elseif roleLv >= threeLv and self.firstOpen[51] == nil then
            self.firstOpen[51] = 1
            UIFirstSmall:OpenFirsySmall()
            self:OpenLvUI(51)
        end
    end
end

function My:OpenLvUI(ID)
    local msg = ProtoPool.GetByID(21085)
    msg.type = ID
    ProtoMgr.Send(msg)
end

function My:RespOpenLv(msg)
    local list = msg.window_open_list
    local len = #list
    for i=1,len do
        local id = list[i]
        if id == 49 then
            self.firstOpen[49] = 1
        elseif id == 50 then
            self.firstOpen[50] = 1
        elseif id == 51 then
            self.firstOpen[51] = 1
        end
    end 
    self.serverCharS = true
    self:LvChange()
end

function My:ProtoHandler(Lsnr)
    Lsnr(21420, self.RespFirstInfo, self)
    Lsnr(21422, self.RespGetAward, self)
    Lsnr(21086, self.RespOpenLv, self)

    Lsnr(22430, self.RespOpenCPM, self)--通过任务触发
end

--day:领取奖励天数
function My:ReqGetAward(day) 
    local msg = ProtoPool.GetByID(21421)
    msg.reward_day = day
    ProtoMgr.Send(msg)
end

function My:RespFirstInfo(msg)
    -- Info.isGet = msg.is_pay --是否充值
    -- Info.openServerDay = msg.pay_time --首充时间，0为未充值
    self:GetPayDay(msg.pay_time)
    local tab = msg.reward_list
    for i = 1,#tab do
        local day = tab[i]
        Info.rewardTab[day] = 1
    end
    self:FirstInfo()
    self.eFirstInfo(reward)
end

--领取奖励返回
function My:RespGetAward(msg)
    local error = msg.err_code
    if error > 0 then
        error = ErrorCodeMgr.GetError(error)
        UITip.Log(error)
        return
    end
    local rewardDay = msg.reward_day
    Info.curRewardDay = rewardDay
    Info.rewardTab[rewardDay] = 1
    self:FirstInfo()
    self.eGetAward()
end

function My:OpenUI(value)
    local isGet = self:IsPayState()
    if isGet == false then
        local needLv = GlobalTemp["130"].Value3
        local lv = tonumber(User.MapData.Level)
        if lv >= needLv then
            if not value then
                self.isShow = true
                UIFirstPay:OpenFirsyPay()
            else
                if not OffRwdMgr.isOpen then
                    UIFirstPay:OpenFirsyPay()
                    self.isShow = true
                end
            end
        end
    end
end

function My:RespOpenCPM(msg)
    local isUpdate = msg.op_type	--0：上线推送 1：更新推送
    local list = msg.id_list
    if isUpdate == 0 then 
        self:GetFirst(list)
    elseif isUpdate == 1 then
        self:OpenFirst(list)
    end
end

function My:GetFirst(list)
    local len = #list
    for i=1,len do
        local id = list[i]
        if id == 49 then
            self.firstOpen[49] = 1
        elseif id == 50 then
            self.firstOpen[50] = 1
        elseif id == 51 then
            self.firstOpen[51] = 1
        end
    end 
end

function My:OpenFirst(list)
    local len = #list
    local isGet = self:IsPayState()
    for i=1,len do
        local id = list[i]
        if id == 49 and self.firstOpen[49] == nil and isGet == false then
            local active = UIMgr.GetActive(UIFirstPay.Name)
            if active == -1 then
                UIFirstCPM:OpenFirsyCPM()
            end
            self.firstOpen[49] = 1
        elseif id == 50 and self.firstOpen[50] == nil and isGet == false then
            UIFirstPay:OpenFirsyPay()
            self.firstOpen[50] = 1
        elseif id == 51 and self.firstOpen[51] == nil and isGet == false then
            UIFirstSmall:OpenFirsySmall()
            self.firstOpen[51] = 1
        end
    end
end

--是否领取第一天奖励
function My:IsGetFDay()
    local val = self:IsPayState()
    local tab = Info.rewardTab
    if val == true and tab[1] then
        return true
    end
    return false
end

function My:FirstInfo()
    self:InitBtnState()
    self:InitRedState()
end

--初始化主界面首充按钮
function My:InitBtnState()
    local k,v = ActivityMgr:Find(ActivityMgr.SC)
    local isHide = self:IsHideMain()
    if isHide == true then
        ActivityMgr:Remove(v)
        LivenessInfo:RemoveActInfo(1004)
        self:Hide()
    end
end

--初始化主界面首充按钮红点状态
function My:InitRedState()
    local isShield = self:IsCanShield()
    if isShield == true then
        return
    end
    local actId = ActivityMgr.SC
    local isShowRed = self:IsMainRed()
    if isShowRed then
        SystemMgr:ShowActivity(actId, 1)
    else
        SystemMgr:HideActivity(actId, 1)
    end
end

--移除主界面首充按钮
function My:Hide()
    local k,v = ActivityMgr:Find(ActivityMgr.SC)
    ActivityMgr:Remove(v)
end

--判断是否显示主界红点
function My:IsMainRed()
    local isHideMain = self:IsHideMain()
    if isHideMain then
        return false
    end
    local openDay = Info.openServerDay
    if openDay > 3 then
        openDay = 3
    end
    local isGet = self:IsPayState()
    local tab = Info.rewardTab
    if isGet == false or openDay == nil then
        return false
    end
    if tab[openDay] == nil then
        return true
    end
    return false
end

--判断是否移出主界按钮
function My:IsHideMain()
    local isHide = true
    local tab = Info.rewardTab
    if tab == nil then
        return false
    end
    local len = #tab
    if len and len >= 3 then
        return true
    end
    for i = 1,3 do
        if tab[i] == nil then
            isHide = false
            break
        end
    end
    return isHide
end

--是否充值
function My:IsPayState()
    local day = Info.openServerDay
    if day == nil or day == 0 then
        return false
    end
    return true
end

--获取已经充值的天数
--payTime:服务器记录的充值时间
function My:GetPayDay(payTime)
    if payTime == nil or payTime == 0 then
        Info.openServerDay = 0
        return
    end
    local curtime = TimeTool.GetServerTimeNow();
    curtime = curtime / 1000;

    --上一个时间
    local lastYear = os.date("%Y",payTime)
    local lastMonth = os.date("%m",payTime)
    local lastDay = os.date("%d",payTime)
    -- iTrace.eError("GS","充值时间： lastYear==",lastYear,"  lastMonth==",lastMonth,"   lastDay==",lastDay)
    -- 当前时间
    local curYear = os.date("%Y", curtime)
    local curMonth = os.date("%m", curtime)
    local curDay = os.date("%d", curtime)
    -- iTrace.eError("GS","当前时间： curYear==",curYear,"  curMonth==",curMonth,"   curDay==",curDay)

    local n_long_time = os.date(os.time{year=curYear,month=curMonth,day=curDay,hour=0,min=0,sec=0})
    local n_short_time = os.date(os.time{year=lastYear,month=lastMonth,day=lastDay,hour=0,min=0,sec=0})

    local t_time = self:Timediff(n_long_time,n_short_time)

    -- local time_txt = string.format("%04d", t_time.year).."年"..
    --                 string.format("%02d", t_time.month).."月"..
    --                 string.format("%02d", t_time.day).."日   "..
    --                 string.format("%02d", t_time.hour)..":"..
    --                 string.format("%02d", t_time.min)..":"..
    --                 string.format("%02d", t_time.sec)

    local day = string.format("%02d", t_time.day)
    day = day + 1

    -- iTrace.eError("GS","相差天数： day==",day)
    Info.openServerDay = day
end

--[[比较两个时间，返回相差多少时间]]  
function My:Timediff(long_time,short_time)  
    local n_short_time,n_long_time,carry,diff = os.date('*t',short_time),os.date('*t',long_time),false,{}  
    local colMax = {60,60,24,os.date('*t',os.time{year=n_short_time.year,month=n_short_time.month+1,day=0}).day,12,0}  
    n_long_time.hour = n_long_time.hour - (n_long_time.isdst and 1 or 0) + (n_short_time.isdst and 1 or 0) -- handle dst  
    for i,v in ipairs({'sec','min','hour','day','month','year'}) do  
        diff[v] = n_long_time[v] - n_short_time[v] + (carry and -1 or 0)  
        carry = diff[v] < 0  
        if carry then  
            diff[v] = diff[v] + colMax[i]
        end  
    end  
    return diff  
end 

function My:Clear()
    Info:Clear()
    self.firstOpen[49] = nil
    self.firstOpen[50] = nil
    self.firstOpen[51] = nil
    self.serverCharS = false
end

function My:Dispose()
    self.firstOpen[49] = nil
    self.firstOpen[50] = nil
    self.firstOpen[51] = nil
    self.serverCharS = false
    self.CPMPa = nil
    self:Clear()
    UserMgr.eLvEvent:Remove(self.LvChange,self)
    self:RemoveProto()
    TableTool.ClearFieldsByName(self, "Event")
end

return My