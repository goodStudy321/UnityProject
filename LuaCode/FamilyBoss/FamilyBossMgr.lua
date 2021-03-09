--[[
 	authors 	:Liu
 	date    	:2018-6-19 15:00:00
 	descrition 	:道庭Boss管理
--]]

FamilyBossMgr = {Name = "FamilyBossMgr"}

local My = FamilyBossMgr

local Info = require("FamilyBoss/FamilyBossInfo")

My.State = false

function My:Init()
    Info:Init()
    self:AddLnsr()
    self.isReq = false
    self.isShow = false
    self.eUpTimer = Event()
    self.eEndTimer = Event()
    self.eUpState = Event()
    self.eUpRank = Event()
    self.eUpMenuRank = Event()
    self.eInspire = Event()
    self.eUpMenu = Event()
    self.eEndMenu = Event()
    self.eWorldLv = Event()
    self:CreateTimer()
end

--添加监听
function My:AddLnsr()
    self:SetLnsr(ProtoLsnr.Add)
    SceneMgr.eOpenScene:Add(self.RespOpenScene, self)
    SceneMgr.eChangeEndEvent:Add(self.RespEnterScene, self)
end

--移除监听
function My:RemoveLsnr()
    self:SetLnsr(ProtoLsnr.Remove)
    SceneMgr.eOpenScene:Remove(self.RespOpenScene, self)
    SceneMgr.eChangeEndEvent:Remove(self.RespEnterScene, self)
end

--设置监听
function My:SetLnsr(func)
    func(26092,self.RespWorldLv, self)
    func(26120,self.RespInfo, self)
    func(26122,self.RespRankInfo, self)
    func(26124,self.RespInspire, self)
    func(26130,self.RespMapRankInfo, self)
    func(26126,self.RespUpMapRank, self)
    func(26152,self.RespEndMenu, self)
    func(26160,self.RespUpInspire, self)
end

--响应打开场景时准备
function My:RespOpenScene(sceneId)
    if sceneId == 30004 then return end
    if User.SceneId == 30004 then
        self.isReq = true
        self:ReqInfo()
    end
end

--响应切换场景结束
function My:RespEnterScene()
    if self.isShow then
        MsgBox.ShowYesNo("道庭神兽掉落已上架至拍卖行，是否前往购买", self.OnYes, self)
    end
    self.isShow = false
    self.isReq = false
end

--点击确定
function My:OnYes()
    UIMgr.Open(UIAuction.Name)
end

--请求道庭Boss信息
function My:ReqInfo()
    local msg = ProtoPool.GetByID(26119)
    ProtoMgr.Send(msg)
end

--响应道庭Boss信息
function My:RespInfo(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    local data = Info.data
    data.type = msg.type
    data.joinCount1 = msg.a_num
    data.hpValue1 = msg.a_hp
    data.joinCount2 = msg.b_num
    data.hpValue2 = msg.b_hp
    self.eUpMenu(msg.type)

    if self.isReq == true then
        local hp = (msg.type==1) and msg.a_hp or msg.b_hp
        if hp <= 0 then
            self.isShow = true
            return
        end
    end
end

--请求排行信息
function My:ReqRankInfo(type)
    local msg = ProtoPool.GetByID(26121)
    msg.type = type
    ProtoMgr.Send(msg)
end

--响应排行信息
function My:RespRankInfo(msg)
    -- iTrace.Error("msg2 = "..tostring(msg))
    self:SetRank(msg)
    self.eUpMenuRank(msg.type)
end

--进图时更新排行信息
function My:RespUpMapRank(msg)
    -- iTrace.Error("msg5 = "..tostring(msg))
    self:SetRank(msg)
    self.eUpRank(msg.type)
end

--响应打开结束面板
function My:RespEndMenu(msg)
    -- iTrace.Error("msg6 = "..tostring(msg))
    local list1 = msg.family
    local list2 = msg.role
    self.eEndMenu(list1, list2)
end

--响应全服鼓舞信息
function My:RespUpInspire(msg)
    -- iTrace.Error("msg7 = "..tostring(msg))
    local data = Info.data
    data.allInspire = msg.all_inspire
    self.eInspire()
end

--进图时响应排行信息（一次）
function My:RespMapRankInfo(msg)
    -- iTrace.Error("msg4 = "..tostring(msg))
    local data = Info.data
    data.type = msg.type
    data.inspire = msg.inspire
    data.allInspire = msg.all_inspire
    data.familyName = msg.self
    self:SetRank(msg)
    self.eUpRank(msg.type)
end

--设置排行
function My:SetRank(msg)
    for i,v in ipairs(msg.list) do
        local rank = v.rank
        local name = v.family_name
        local joinCount = v.num
        local hurtNum = v.hurt_num
        Info:UpRankData(msg.type, rank, name, joinCount, hurtNum)
    end
end

--请求鼓舞
function My:ReqInspire()
    local msg = ProtoPool.GetByID(26123)
    ProtoMgr.Send(msg)
end

--响应鼓舞
function My:RespInspire(msg)
    -- iTrace.Error("msg3 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		UITip.Error(ErrorCodeMgr.GetError(err))
        return
    end
    Info.data.inspire = msg.inspire
    Info.data.allInspire = msg.all_inspire
    self.eInspire()
end

--响应世界等级
function My:RespWorldLv(msg)
    Info.worldLv = msg.level
    -- Info.server_id=msg.server_id
    -- Info.server_name=msg.server_name
    self.eWorldLv()
end

--响应道庭Boss活动状态
function My:RespFamilyBossActiv(status, endTime)
    if status == 2 then
        self.State = true
        local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
        local leftTime = endTime - sTime
        self:UpTimer(leftTime)
    else
        self.State = false
    end
    self.eUpState(status)
    self:UpAction()
end

--更新红点
function My:UpAction()
    local state = self:IsShowAction()
    FamilyMgr.eRed(state, 3, 3);
end

--是否显示红点
function My:IsShowAction()
    local data = Info.data
    local value = (data.type==1) and data.hpValue1 or data.hpValue2 
    return self.State and value > 0
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
	timer:Start()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    self.eUpTimer(time)
end

--结束倒计时
function My:EndCountDown()
	self.eEndTimer()
end
    
--清理缓存
function My:Clear()
    Info:Clear()
    self.isShow = false
    self.isReq = false
    if self.timer then self.timer:Stop() end
end
    
--释放资源
function My:Dispose()
    self:RemoveLsnr()
    TableTool.ClearFieldsByName(self,"Event")
end

return My