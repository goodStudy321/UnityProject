--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/9/9 下午2:36:29
-- 砸蛋管理类
-- 活动ID:在活动周期表中描述, 暂时为2002
--=============================================================================


ZaDanMgr = Super:New{ Name = "ZaDanMgr" }
require("Data/ZaDan/ZaDanInfo")
require("Data/ZaDan/ZaDanLog")

local My = ZaDanMgr
local GetErr = ErrorCodeMgr.GetError
My.flag = require("Data/ZaDan/ZaDanFlag")

----BEG PUBLIC

function My:Init()
    self.sysID = 2002
    self.actInfo = NewActivMgr:GetActivInfo(sysID)
    --条目:(ZaDanInfo)
    self.infos = {}

    --k:id,V:1:不能领,2:可领,3:已领
    self.getDic = {}
    --稀有记录列表(ZaDanLog)
    self.highLogs = {}
    --普通记录列表(ZaDanLog)
    self.normLogs = {}

    --稀有记录上限
    self.highMax = 5
    --普通记录上限
    self.normMax = 30

    self:Reset()
    self:InitProp()
    self:InitInfos()
    self:AddLsnr()
    self.flag:Init()
end

function My:InitProp()
    local cfg = GlobalTemp["184"]
    self.cfg = cfg
    local vals = cfg.Value2
    --单次砸开消耗金钱
    self.oneConGold = vals[1]
    --消耗道具ID
    self.hammerID = vals[2]
    --单次消耗锤子
    self.oneConHarm = vals[3]
    --刷新消耗金钱
    self.refreshGold = vals[4]
    --最大累计次数
    self.maxTime = ZaDanAddUpCfg[#ZaDanAddUpCfg].cond
end

function My:Reset()
    --拥有的锤子
    self.hammer = 0
    --true:免费刷新
    self.canRefresh = false

    self.times = 0

    --活动信息(在NewActivMgr中存储的条目引用)
    self.actInfo = nil 

    TableTool.ClearDic(self.getDic)
end

--是否开启
function My:IsOpen()
    local actInfo = self.actInfo
    if actInfo == nil then return false end
    return (actInfo.val == 1)
end

--初始化信息列表
function My:InitInfos()
        
    local infos = self.infos
    for i = 1, 8 do
        local info = ObjPool.Get(ZaDanInfo)
        info:Set()
        infos[#infos + 1] = info
    end
end

--重置信息列表
function My:ResetInfos()
    for i, v in ipairs(self.infos) do
        v:Dispose()
    end
end

function My:SetGetDic(list)
    if list == nil then return end
    local dic = self.getDic
    for i,v in ipairs(list) do
        local k = tostring(v.id) 
        dic[k] = v.val
    end
end

function My:GetHammarID()
    do return self.hammerID end
end

--获取砸蛋总消耗
--count(number):砸蛋数量
function My:GetAllConGold(count)
    count = count or 0
    local total = self.oneConGold * count
    return total
end

--获取未砸开数量
function My:GetNotOpenCount()
    local total = 0
    for i, v in ipairs(self.infos) do
        if v.itID == 0 then
            total = total + 1
        end
    end
    return total
end

function My:GetOneConGold()
    do return self.oneConGold end
end

function My:GetOneConHarm()
    do return self.oneConHarm end
end

function My:GetHammar()
    do return self.hammer end
end

function My:GetRefreshGold(count)
    count = count or 1
    local total = count * self.refreshGold
    return total
end

--获取剩余砸蛋时消耗的金钱
function My:GetRefreshGoldByNotOpen()
    local count = self:GetNotOpenCount()
    return self:GetRefreshGold(count)
end


--获取世界等级
function My:GetWorldLv()
    local lv = self.actInfo and self.actInfo.worldLevel or 0
    return lv
end

--获取套序号
function My:GetConfigNum()
    local num =  (self.actInfo and self.actInfo.configNum or 0)
    return num
end

function My:GetEndTime()
    local tm = self.actInfo and self.actInfo.endTime or 0
    return tm
end

--领取奖励状态
--id(number):奖励配置ID
function My:GetRewardState(id)
    local k = tostring(id)
    local state = self.getDic[k]
    if state == nil then
        local cfg = BinTool.Find(ZaDanAddUpCfg, id)
        if cfg then
            if (self.times < cfg.cond) then
                state = 1
            else
                state = 2
            end
        end
    elseif state == 1 then
        local cfg = BinTool.Find(ZaDanAddUpCfg, id)
        if cfg and (self.times>= cfg.cond) then
            state = 2
        end
    end
    return state
end

function My:Clear()
    self:Reset()
    UIMgr.Close("UIZaDan")
end

function My:AddLsnr()
    --上线更新事件
    self.eInfo = Event()
    --砸蛋更新事件
    self.eZaDan = Event()
    --刷新事件
    self.eRefresh = Event()
    --记录变更事件
    self.eRecord = Event()
    --免费刷新事件
    self.eRefreshFree = Event()
    --领取事件
    self.eRespGet = Event()
    --开启状态变更事件
    self.eSysState = Event()

    local Add = ProtoLsnr.Add
    Add(26482, self.RespInfo, self)
    Add(26484, self.RespZaDan, self)
    Add(26486, self.RespRefresh, self)
    Add(26488, self.RespRecord, self)
    Add(26490, self.RespRefreshFree, self)
    Add(26492, self.RespGet, self)

    NewActivMgr.eUpActivInfo:Add(self.SysOpen, self)
end

function My:SysOpen(id)
    local sysID = self.sysID
    local need = nil
    if id == nil then
        need = true
    elseif id == sysID then
        need = true
    end
    if need then
        self.actInfo = NewActivMgr:GetActivInfo(sysID)
        self.eSysState(self.actInfo)
    end
end


function My:RespInfo(msg)
    self:SetInfos(msg.eggs)
    self:SetGetDic(msg.list)
    self:SetLogs(self.normLogs, msg.a_log)
    self:SetLogs(self.highLogs, msg.b_log)
    self.times = msg.open_times
    self.canRefresh = msg.can_refresh
    self.eInfo(msg)
end

--list:p_egg列表
function My:SetInfos(list)
    local infos = self.infos
    for i,v in ipairs(list) do
        local info = infos[v.id]
        info:SetByMsg(v)
    end
end

--logs:ZaDanLog列表
--list:p_kvs列表
function My:SetLogs(logs, list)
    if list == nil then return end
    ListTool.ClearToPool(self.logs)
    for i,v in ipairs(list) do
        local log = ObjPool.Get(ZaDanLog)
        log:SetByMsg(v) 
        logs[#logs + 1] = log
    end
end

--添加记录
function My:AddLogs(logs, list, max)
    if list == nil then return end
    local addLen = #list
    if addLen < 1 then return end
    local hasLen = #logs

    local total = addLen + hasLen
    local dif = total - max

    if dif > 0 then
        for i=1,dif do
            local log = table.remove(logs)
            ObjPool.Add(log)
        end
    end
    for i,v in ipairs(list) do
        local log = ObjPool.Get(ZaDanLog)
        log:SetByMsg(v) 
        table.insert(logs, 1, log)
    end
end

--(number)1-8,0代表其它全砸
function My:ReqZaDan(id)
    local itCnt = ItemTool.GetNum(self.hammerID)
    local oneCon = self:GetOneConHarm()
    local count = 1
    if id == 0 then
        count = self:GetNotOpenCount()
    end
    local totalCon = oneCon * count
    if itCnt < totalCon then
        local totalGold = self:GetOneConGold() * count
        if RoleAssets.Gold < totalGold then
            UITip.Error("道具和元宝不足")
            return false
        end
    end
    self:DirectReqZaDan(id)
    return true
end

function My:DirectReqZaDan(id)
    local msg = ProtoPool.GetByID(26483)
    msg.num = id
    ProtoMgr.Send(msg)
end

function My:RespZaDan(msg)
    local err = msg.err_code
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
    else
        self:SetInfos(msg.eggs)
        self.times = msg.open_times
        self.canRefresh = msg.can_refresh
    end
    self.eZaDan(msg)
end

function My:ReqRefresh()
    if not self.canRefresh then
        local gold = self:GetRefreshGoldByNotOpen()
        if RoleAssets.Gold < gold then
            UITip.Error("元宝不足")
            return false
        end
    end
    local msg = ProtoPool.GetByID(26485)
    ProtoMgr.Send(msg)
    return true
end

function My:RespRefresh(msg)
    local err = msg.err_code
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
    else
        self:SetInfos(msg.eggs)
        self.canRefresh = msg.can_refresh
    end
    self.eRefresh(msg)
end

function My:RespRecord(msg)
    local highLogs, normLogs = self.highLogs, self.normLogs
    self:AddLogs(normLogs, msg.a_log, self.normMax)
    self:AddLogs(highLogs, msg.b_log, self.highMax)
    self.eRecord(highLogs, normLogs)
end

function My:RespRefreshFree(msg)
    self.canRefresh = true
    self.eRefreshFree(true)
end

function My:ReqGet(id)
    local msg = ProtoPool.GetByID(26491)
    msg.id = id
    ProtoMgr.Send(msg)
end

function My:RespGet(msg)
    local err = msg.err_code
    if err > 0 then
        MsgBox.ShowYes(GetErr(err))
    else
        self.getDic[tostring(msg.id)] = 3
    end
    self.eRespGet(msg)
    --TODO
end

----END PUBLIC
return My