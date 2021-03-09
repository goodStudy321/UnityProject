--[[
 	authors 	:Liu
 	date    	:2019-4-18 11:00:00
 	descrition 	:仙途之路管理
--]]

JourneysMgr = {Name = "JourneysMgr"}

local My = JourneysMgr

function My:Init()
    self.mana = 0--仙力值
    self.countDic = {}--已完成次数
    self.awardDic = {}--奖励状态

    self.eGetAward = Event()
    self:SetLnsr(ProtoLsnr.Add)
end

function My:SetLnsr(func)
    func(26076,self.RespInfo,self)
    func(26078,self.RespGetAward,self)
    func(26080,self.RespAddMission,self)
    func(26082,self.RespUpInfo,self)
end

--响应上线推送信息
function My:RespInfo(msg)
    self.mana = msg.score
    for i,v in ipairs(msg.mission_list) do
        local key = tostring(v.id)
        self.countDic[key] = v.val
    end
    for i,v in ipairs(msg.reward_list) do
        local key = tostring(v.id)
        self.awardDic[key] = v.val
    end
    self:UpAction()
end

--请求领取奖励
function My:ReqGetAward(id)
    local msg = ProtoPool.GetByID(26077)
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应领取奖励
function My:RespGetAward(msg)
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local key = tostring(msg.id)
    if self.awardDic[key] then
        self.awardDic[key] = 3
    end
    self.eGetAward()
    self:UpAction()
end

--响应新增任务
function My:RespAddMission(msg)
    for i,v in ipairs(msg.mission_list) do
        local key = tostring(v.id)
        self.countDic[key] = v.val
    end
end

--响应更新信息
function My:RespUpInfo(msg)
    self.mana = msg.score
    for i,v in ipairs(msg.mission_list) do
        local key = tostring(v.id)
        self.countDic[key] = v.val
    end
    for i,v in ipairs(msg.reward_list) do
        local key = tostring(v.id)
        self.awardDic[key] = v.val
    end
    self:UpAction()
end

--更新红点
function My:UpAction()
    local isShow = self:IsShowAction()
    LimitActivMgr:UpAction(1, isShow)
end

--是否显示红点
function My:IsShowAction()
    for k,v in pairs(self.awardDic) do
        if v == 2 then
            return true
        end
    end
    return false
end

--清理缓存
function My:Clear()
    self.mana = 0
    TableTool.ClearDic(self.countDic)
    TableTool.ClearDic(self.awardDic)
end

--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
end

return My