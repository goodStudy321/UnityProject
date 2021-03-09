
-- AwardItemMgr = {Name = "AwardItemMgr"}
-- local AM = AwardItemMgr
-- local CheckErr = ProtoMgr.CheckErr

-- local Info = require("Data/OpenService/AccuPayInfo")

-- function AM:Init()
--     self:Clear()
--     self.eAwardInfo = Event()
--     self.eAward = Event()
--     self:AddProto()
-- end

-- function AM:AddProto()
--     self:ProtoHandler(ProtoLsnr.Add)   
-- end

-- function AM:RemoveProto()
--     self:ProtoHandler(ProtoLsnr.Remove)
-- end

-- --设置监听
-- function AM:ProtoHandler(Lsnr)
--     Lsnr(21410, self.RespAccuMsg, self)
--     Lsnr(21412, self.RespAccuReward, self)
-- end

-- --请求
-- function AM:ReqGetAwardWord(key)
--     local msg = ProtoPool.GetByID(21411)
--     msg.key = key
--     ProtoMgr.Send(msg)
-- end

-- --开服累积信息返回
-- function AM:RespAccuMsg(msg)
--     local reward = msg.reward
--     for i,j in ipairs(reward) do
--         local key = j.id
--         local value = j.val
--         Info.RewardDic[key] = value
--     end
--     Info.selfPay = msg.recharge
--     self.eAwardInfo(reward)
-- end

-- --领取累积奖励返回
-- function AM:RespAccuReward(msg)
--     local error = msg.err_code
--     if error>0 then
--         MsgBox.ShowYes(ErrorCodeMgr.GetError(error))
--         return
--     end
--     self.eAward(msg.reward_key)
-- end

-- --清理缓存
-- function AM:Clear()
    
-- end

-- --释放资源
-- function AM:Dispose()
--     self:RemoveProto()
--     TableTool.ClearFieldsByName(self,"Event")
-- end

-- return AM