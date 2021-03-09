
EvrDayMgr = {Name = "EvrDayMgr"}
local EM = EvrDayMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

local Info = require("Data/OpenService/EvrDayInfo")

function EM:Init()
    self:Clear()
    self.isShow = false
    self.eDayInfo = Event()
    self.eGetReward = Event()
    self.eGetCountReward = Event()
    self:AddProto()
end

function EM:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)   
    ActivStateMgr.eUpActivState:Add(self.RespUpActivState, self)
end

function EM:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
    ActivStateMgr.eUpActivState:Remove(self.RespUpActivState, self)
end

function EM:ProtoHandler(Lsnr)
    Lsnr(21400, self.RespDayRecharge, self)
    Lsnr(21402, self.RespGetReward, self)
    Lsnr(21404, self.RespGetCountReward, self)
end

--请求领取每日累充奖励
function EM:ReqGetReward(id)
    local msg = ProtoPool.GetByID(21401)
    msg.key = id
    Send(msg)
end

--请求领取每日累计累充奖励
function EM:ReqGetCountReward(id)
    local msg = ProtoPool.GetByID(21403)
    msg.day = id
    Send(msg)
end

--每日累充信息返回
function EM:RespDayRecharge(msg)
    Info.Recharge = msg.recharge
    Info.OpenDay = msg.day
    for i,j in ipairs(msg.day_reward) do
        Info.PayAdDic[j.id] = j.val
    end
    for k,v in ipairs(msg.count_reward) do
        Info.CountAdDic[v.id] = v.val
    end
    self:InitRedState()
    self.eDayInfo()

    if not OffRwdMgr.isOpen then
        --self:IsOpenMenu()
    end
end

--上线时是否打开界面
function EM:IsOpenMenu()
    local isOpen = LivenessInfo:IsOpen(1006)
    if isOpen == false then return end
    if not self.isShow then
        self.isShow = true
        if FirstPayMgr:IsPayState() == true then
            local lv = GlobalTemp["130"].Value3
            if Info.Recharge < 60 and User.MapData.Level >= lv then
                UIMgr.Open(UIEvrDayPay.Name)
            end
        end
    end
end

--领取每日累充奖励
function EM:RespGetReward(msg)
    local error = msg.err_code
    if error>0 then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(error))
        return
    end
    local id = msg.reward.id
    local val = msg.reward.val
    Info.PayAdDic[id] = val
    self:InitRedState()
    self.eGetReward(msg.reward)
end

--领取每日累计累充奖励
function EM:RespGetCountReward(msg)
    local error = msg.err_code
    if error>0 then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(error))
        return
    end
    Info.CountAdDic[msg.day] = 3
    self:InitRedState()
    self.eGetCountReward(msg.day)
end

--更新活动状态
function EM:RespUpActivState()
    self:InitRedState()
end

function EM:InitRedState()
    local actId = ActivityMgr.MRLC
    local isGet = self:IsGetAward()
    local isOpen = LivenessInfo:IsOpen(1006)
    if isGet and isOpen then
        SystemMgr:ShowActivity(actId)        
    else
        SystemMgr:HideActivity(actId)       
    end
end

function EM:IsGetAward()
    local isGet = false
    for i,j in pairs(Info.PayAdDic) do
        if j==2 then
            isGet = true
        end
    end
    for k,v in pairs(Info.CountAdDic) do
        if v==2 then
            isGet = true
        end
    end
    return isGet
end

--清理缓存
function EM:Clear()
    Info:Clear()
end

--释放资源
function EM:Dispose()
    self:RemoveProto()
    TableTool.ClearFieldsByName(self, "Event")
end

return EM