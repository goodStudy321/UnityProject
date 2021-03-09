
require("Proto/ProtoMgr")

CollWordsMgr = {Name = "CollWordsMgr"}
local CM = CollWordsMgr
local CheckErr = ProtoMgr.CheckErr

local Info = require("Data/OpenService/CollWordsInfo")

function CM:Init()
    self:Clear()
    self.benefitMgr = BenefitMgr
    self.eCollMsg = Event()
    self.eGetAward = Event()
    self:AddProto()
end

function CM:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
    PropMgr.eUpdate:Add(self.UpdateAllCollState, self)
end

function CM:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
    PropMgr.eUpdate:Remove(self.UpdateAllCollState, self)
end

--设置监听
function CM:ProtoHandler(Lsnr)
    Lsnr(21432, self.RespCollMsg, self)
    Lsnr(21434, self.RespCollAward, self)
end

--集字奖励请求
function CM:ReqGetAward()
    local msg = ProtoPool.GetByID(21431)
    ProtoMgr.Send(msg)
end

--领取奖励请求
function CM:ReqGetCollAward(id)
    local msg = ProtoPool.GetByID(21433)
    msg.reward = id
    ProtoMgr.Send(msg)
end

--集字奖励信息返回
function CM:RespCollMsg(msg)
    local error = msg.err_code
    if not CheckErr(error) then
        UITip.Error(ErrorCodeMgr.GetError(error))
        return
    end
    local reward = msg.reward
    local isRed = false
    for i,j in ipairs(reward) do
        local key = j.id
        CollWordsInfo.countDic[key] = j.val
    end
    self:UpdateAllCollState()
    self.eCollMsg(msg)
end

--集字领取奖励返回
function CM:RespCollAward(msg)
    local error = msg.err_code
    if error>0 then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(error))
        return
    end
    self.eGetAward()
end

function CM:GetCollState(index)
    local collCfg = CollWordsCfg
    local collData = collCfg[index]
    local useTab = collData.use
    local useLen = #useTab
    local isRed = false
    local indexs = 0
    for k,v in pairs(useTab) do
        local id = v.k
        local num = ItemTool.GetNum(id)
        if num > 0 then
            indexs = indexs + 1
        end
    end
    if indexs ~= 0 and indexs == #useTab then
        return true
    end
    return false
end

function CM:UpdateAllCollState()
    local collCfg = CollWordsCfg
    local isRed = false
    for k,v in ipairs(collCfg) do
        local times = CollWordsInfo.countDic[k]
        if times == nil then return end
        if times > 0 then
            isRed = self:GetCollState(k)
        end
        if isRed == true then
            break
        end
    end
    self.benefitMgr.eUpdateRedPoint(isRed, 5)
    self.benefitMgr.state[5] = isRed
    self.benefitMgr:UpdateAllRedPoint()
end

--清理缓存
function CM:Clear()
    CollWordsInfo:Clear()
end

--释放资源
function CM:Dispose()
    self:Clear()
    self:RemoveProto()
    TableTool.ClearFieldsByName(self,"Event")
end

return CM