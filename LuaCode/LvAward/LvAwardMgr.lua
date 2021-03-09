--[[
 	authors 	:Liu
 	date    	:2018-5-22 19:28:08
 	descrition 	:等级奖励管理
--]]

LvAwardMgr = {Name = "LvAwardMgr"}

local My = LvAwardMgr

local Info = require("LvAward/LvAwardInfo")

--红点列表(1.冲级豪礼 2.七日登陆 3.每日签到 4.好评奖励 5.祈福 9.全服红包)
My.actionDic = {}
My.eUpAction = Event()

function My:Init()
    Info:Init()
    self.eLvAward = Event()
    self.eWordLvAward = Event()
    self.eUpLvAwardInfo = Event()
    self:SetLnsr(ProtoLsnr.Add)
    UserMgr.eLvEvent:Add(self.LvChange, self)
end

--设置监听
function My:SetLnsr(func)
    func(20380,self.RespLvAwardInfo, self)
    func(20382,self.RespLimitedAward, self)
    func(20384,self.RespLvAward, self)
end

--请求获取等级奖励
function My:ReqGetLvAward(level)
    if UILvAward then UILvAward:Lock(true) end
    local msg = ProtoPool.GetByID(20383)
    msg.level = level
	ProtoMgr.Send(msg)
end

--响应所有等级奖励信息
function My:RespLvAwardInfo(msg)
    local wordList = msg.world_level_list
    local selfList = msg.my_level_list
    
    for i,v in ipairs(wordList) do
        local key = tostring(v.id)
        Info.worldDic[key] = v.val
    end
    for i,v in ipairs(selfList) do
        local key = tostring(v)
        Info.selfDic[key] = true
    end
    self.eUpLvAwardInfo()
    self:UpRedDot()
end

--响应限制奖励数量
function My:RespLimitedAward(msg)
    local id = msg.act_level.id
    local val = msg.act_level.val
    local key = tostring(id)
    Info.worldDic[key] = val
    self.eWordLvAward(key)
    self:UpRedDot()
end

--响应领取等级奖励
function My:RespLvAward(msg)
    if UILvAward then UILvAward:Lock(false) end
	local err = msg.err_code
	if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
    end
    local key = tostring(msg.level)
    Info.selfDic[key] = true
    self.eLvAward(key)
    self:UpRedDot()
end

--响应等级变化
function My:LvChange()
    local roleLv = UserMgr:GetRealLv()
    self:UpRedDot()
end

--更新红点（外部调用）
function My:UpAction(k,v)
	local key = tostring(k)
	if type(key) ~= "string" or type(v) ~= "boolean" then
		iTrace.Error("传入的参数错误")
		return
    end
	My.actionDic[key] = v
	self:UpRedDotState()
	My.eUpAction()
end

--更新红点
function My:UpRedDotState()
	for k,v in pairs(My.actionDic) do
        local index = tonumber(k)
		self:ChangeRedDot(v, index)
    end
end

--改变红点状态
function My:ChangeRedDot(state, index)
    local actId = ActivityMgr.CJHL
    if state then
        SystemMgr:ShowActivity(actId, index)
    else
        SystemMgr:HideActivity(actId, index)
    end
end

--更新红点
function My:UpRedDot()
    if User.MapData.Level < 25 then return end
    local isGet1 = self:IsGetAward()
    self:UpAction(1, isGet1)
end

--判断是否能领取等级奖励
function My:IsGetAward()
    local dic1 = {}
    local dic2 = {}
    local lv = User.MapData.Level
    for k,v in pairs(Info.selfDic) do
        dic1[k] = v
    end
    for k,v in pairs(Info.worldDic) do
        if dic1[k] then
            dic1[k] = v
        end
    end
    for i,v in ipairs(LvAwardCfg) do
        if lv >= v.id then
            local key = tostring(v.id)
            dic2[key] = v.count
        end
    end
    for k,v in pairs(dic2) do
        if not dic1[k] then
            local cfg, index = BinTool.Find(LvAwardCfg, tonumber(k))
            if cfg.count == 0 or cfg.count ~= Info.worldDic[k] then
                return true
            end
        end
    end
    return false
end

--清理缓存
function My:Clear()
    Info:Clear()
    TableTool.ClearDic(My.actionDic)
end

--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
	TableTool.ClearFieldsByName(self,"Event")
end

return My