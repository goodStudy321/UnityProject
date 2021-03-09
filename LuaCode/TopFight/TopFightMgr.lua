--[[
 	authors 	:Liu
 	date    	:2018-9-21 11:00:00
 	descrition 	:青云之巅管理
--]]

TopFightMgr = {Name = "TopFightMgr"}

local My = TopFightMgr

local Info = require("TopFight/TopFightInfo")

My.State = false

function My:Init()
    Info:Init()
    self:SetLnsr(ProtoLsnr.Add)
    self.eUpState = Event()
    self.eUpTimer = Event()
    self.eEndTimer = Event()
    self.eTopInfo = Event()
    self.eUpTopInfo = Event()
    self.UpRank = Event()
    self.UpSelfRank = Event()
    self:CreateTimer()
end

--设置监听
function My:SetLnsr(func)
    func(22300,self.RespTopInfo, self)
    func(22302,self.RespTopUp, self)
    func(22304,self.RespTopRank, self)
end

--响应信息
function My:RespTopInfo(msg)
    local score = msg.score
    local rank = msg.rank
    Info:SetSelfInfo(score, rank)
    self.eTopInfo(score, rank)
    -- iTrace.Error("score = "..score.." rank = "..rank)
end

--响应更新
function My:RespTopUp(msg)
    -- iTrace.Error("id = "..msg.update.id.." val = "..msg.update.val)
    local id = msg.update.id
    local val = msg.update.val
    if id == 1 then
        Info.score = val
    elseif id == 2 then
        Info.rank = val
    end
    self.eUpTopInfo(Info.score, Info.rank)
end

--响应排行
function My:RespTopRank(msg)
    local isRank = false
    UIMgr.Open(UITopFightEnd.Name)
    Info.useTime = msg.use_time
    for i,v in ipairs(msg.ranks) do
        local rank = v.rank
        local name = v.role_name
        local time = v.use_time
        local roleId = v.role_id
        local floor = v.floor
        local score = v.score
        if roleId == User.MapData.UIDStr then
            isRank = true
        end
        self.UpRank(rank, name, time, roleId, isRank, floor, score)
        -- iTrace.Error("rank = "..tostring(v.rank).." role_id = "..tostring(v.role_id).." role_name = "..tostring(v.role_name).." floor = "..tostring(v.floor).." score = "..tostring(v.score).." use_time = "..tostring(v.use_time))
    end
    if not isRank then self.UpSelfRank(Info.useTime) end
end

--响应活动状态
function My:RespActivInfo(status, endTime)
    if status == 2 then
        self.State = true
        local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
        local leftTime = endTime - sTime
        self:UpTimer(leftTime)
    else
        self.State = false
    end
    self.eUpState(status)
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
    timer.fmtOp = 3
	timer.apdOp = 1
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    self.eUpTimer(self.timer.remain, time)
end

--结束倒计时
function My:EndCountDown()
	self.eEndTimer()
end

--清理缓存
function My:Clear()
    Info:Clear()
    if self.timer then self.timer:Stop() end
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
end

return My