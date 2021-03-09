
AccuPayMgr = {Name = "AccuPayMgr"}
local AM = AccuPayMgr
local CheckErr = ProtoMgr.CheckErr

local Info = require("Data/OpenService/AccuPayInfo")

function AM:Init()
    self:Clear()
    self.benefitMgr = BenefitMgr
    self.eAwardInfo = Event()
    self.eAward = Event()
    self:AddProto()
end

function AM:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)   
end

function AM:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

--设置监听
function AM:ProtoHandler(Lsnr)
    Lsnr(21410, self.RespAccuMsg, self)
    Lsnr(21412, self.RespAccuReward, self)
end

--请求
function AM:ReqGetAwardWord(key)
    local msg = ProtoPool.GetByID(21411)
    msg.key = key
    ProtoMgr.Send(msg)
end

--开服累积信息返回
function AM:RespAccuMsg(msg)
    local reward = msg.reward
    -- Info:Dispose()
    -- TableTool.ClearDicToPool(Info.RewardDic)
    Info.RewardDic = {}
    for i,j in ipairs(reward) do
        local key = j.id
        local value = j.val
        if Info.RewardDic[key] == nil then
            Info.RewardDic[key] = value
        end
    end
    Info.selfPay = msg.recharge
    self:UpdateRedPoint()
    self.eAwardInfo(reward)
end

--领取累积奖励返回
function AM:RespAccuReward(msg)
    local error = msg.err_code
    if error>0 then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(error))
        return
    end
    Info.RewardDic[msg.reward_key] = 3
    self:UpdateRedPoint()
    self.eAward(msg.reward_key)
end

function AM:UpdateRedPoint()
    local state = false
    local dic = Info.RewardDic
    for k,v in pairs(dic) do
        if v == 2 then
            state = true
            break
        end
    end
    -- VIPMgr.UpAction("4", state)
    self.benefitMgr.eUpdateRedPoint(state, 1)
    self.benefitMgr.state[1] = state
    self.benefitMgr:UpdateAllRedPoint()
end

--清理缓存
function AM:Clear()
    
end

--释放资源
function AM:Dispose()
    self:RemoveProto()
    TableTool.ClearFieldsByName(self,"Event")
end

return AM