LvLimitBuyMgr=Super:New{Name="LvLimitBuyMgr"}
 
local M=LvLimitBuyMgr

local iLog = iTrace.Log
local iError = iTrace.Error

local ET = EventMgr.Trigger;

function M:Init()
    self.eOpenOrClose=Event()
    self.eUpdate = Event()
    self.eUpdateTime = Event()
    --self.eUpTime = Event()

    self.IsOpen = false
    self.index = 0
    self.init = false;
    self.status = 0
    self:SetLsner(ProtoLsnr.Add)
end

function M:SetLsner(fun)
    fun(22834,self.RespDayInfo,self)
    fun(22836,self.RespDayBuy,self)
end

--==============================--

function M:RespDayInfo(msg)
    self.dataList={}
    self.sortData = {}
    local list = msg.list
    for i,v in ipairs(list) do
        self:SetData(v)
    end
    self.eOpenOrClose(true)
    self:SetTime()
end

function M:RespDayBuy(msg)
    if msg.err_code == 0 then
        local id = msg.id
        self:UpItem(id)
        self:SetTime()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

function M:ReqBuy(id)
    local msg = ProtoPool.GetByID(22835)
    msg.id = id
    ProtoMgr.Send(msg)
end
--==============================--

-- 设置时间
function M:SetTime()
    if #self.sortData > 0 then
        table.sort(self.sortData,self.Sort)
        local time = self.sortData[1].time
        self:StartTimer(time)
    end
end

function M.Sort(a,b)
    return a.time <b.time
end

-- 创建倒计时时间
function M:StartTimer(eTime)
    if not eTime then return end
    if not self.timer then
        self.timer=ObjPool.Get(DateTimer)
    end
    local timer = self.timer
    timer:Stop()
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = eTime - now
    if dValue<=0 then
        timer.remain = ""
        self:EndTime()
    else
        timer.seconds=dValue
        timer.fmtOp = 3
        timer.apdOp = 1
        timer.invlCb:Add(self.UpTime,self)
        timer.complete:Add(self.EndTime, self)
        timer:Start()
        self:UpTime()
    end
end

function M:UpTime()
    local time = self.timer.remain

    self.eUpdateTime(time)
end

function M:EndTime()
    self:StopTimer()
    if #self.sortData > 1 then
        table.remove(  self.sortData, 1 )
        self:SetTime()
    else
        self.eOpenOrClose(false)
    end
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
end

function M:SetData(value)
    local id = value.id;
    local item={}
    item.id=id
    item.time = value.end_time
    self:SetRWd(item,value.goods_list)
    item.name=ItemData[tostring(item.award.id)].name
    item.monType = value.asset_type
    item.price = value.old_price
    item.newPrice = value.now_price
    item.disCNum = value.discount
    table.insert(self.dataList,item)
    table.insert(self.sortData,item)
end

--设置奖励
function M:SetRWd(item,list)
    if list == nil then
        return;
    end
    if #list == 0 then
        return;
    end
    local rwd = {}
    rwd.id = list[1].id
    rwd.num = list[1].val;
    item.award = rwd;
end

function M:UpItem(id)
    for i=#self.dataList,1,-1 do
        if self.dataList[i].id == id then
            table.remove(self.dataList,i)
            self.eUpdate()
            break
        end
    end
    self.sortData = self.dataList
    if #self.dataList == 0 then
        local active = UIMgr.GetActive(UILvLimitBuyWnd.Name)
        if active ~= -1 then
            UIMgr.Close(UILvLimitBuyWnd.Name)
        end
        self.eOpenOrClose(false)
        return
    end
end
-- 不再提醒界面状态设置
-- function M:SetStatus(status)
--     self.status = status
-- end

-- function M:GetStatus()
--     return self.status
-- end

--//得到展示格子的列表
function M:GetDataList()
    if self.dataList ~= nil then
        table.sort(self.dataList,M.Sort)
    end
    return self.dataList
end
function M.Sort(a,b)
    return a.id < b.id
end

function M:Clear()
    self.IsOpen = false
    self.index = 0
    --self.status = 0
    self:StopTimer()
    self.eOpenOrClose(false)
end

return M