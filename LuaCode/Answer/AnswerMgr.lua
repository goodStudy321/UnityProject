--[[
 	authors 	:Liu
 	date    	:2018-4-9 12:28:08
 	descrition 	:答题管理
--]]

AnswerMgr = {Name = "AnswerMgr"}

local My = AnswerMgr

local Info = require("Answer/AnswerInfo")

My.State = false

function My:Init()
    Info:Init()
    self:CreateTimer()
    self:AddLnsr()
    self.eUpShow = Event()
    self.eUpRank = Event()
    self.eUpState = Event()
    self.eUpTimer = Event()
    self.eEndTimer = Event()
    self.eUpExp = Event()
    self.eHurt = Event()
    self.eAnswer = Event()
end

--添加监听
function My:AddLnsr()
    self:SetLnsr(ProtoLsnr.Add)
end

--移除监听
function My:RemoveLsnr()
    self:SetLnsr(ProtoLsnr.Remove)
end

--设置监听
function My:SetLnsr(func)
    func(20402,self.RespAnswerHurt, self)
    func(20404,self.RespQuestion, self)
    func(20406,self.RespRankInfo, self)
    func(20408,self.RespExp, self)
    func(20410,self.RespAnswer, self)
end

--响应答案返回
function My:RespAnswer(msg)
    self.eAnswer(msg.res)
end

--请求答题技能攻击
function My:ReqAnswerAtk(skill, pos, target)
    if tostring(target) == "0" then  return end
    local msg = ProtoPool.GetByID(20401)
    msg.skill = skill
    msg.pos = pos
    --给协议列表添加元素
    msg.target:append(target)
    ProtoMgr.Send(msg)
    -- iTrace.Log("skill = "..skill.."pos = "..pos.."target = "..target)
end

--响应答题受击（技能1：干扰，技能2：踢飞）
function My:RespAnswerHurt(msg)
    local skill = msg.skill
    if skill == 1 then
        --自身受到BUFF影响
        FindHelper.instance:GetSelfGo():AddComponent(typeof(UnitFrMove))
    end
    self.eHurt(skill)
end

--响应题目
function My:RespQuestion(msg)
    local ques = msg.question
    local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
    local leftTime = msg.time - sTime
    Info.ques = ques
    self.eUpShow(leftTime, ques, msg.num)
    -- iTrace.Log("time = "..leftTime.."ques = "..ques)
end

--响应排行榜信息
function My:RespRankInfo(msg)
    Info.curScore = msg.add_score
    self:SetData(Info.sRank, msg.self)
    Info.isEnd = msg.is_end
    for i,v in ipairs(msg.rank_list) do
        local key = tostring(v.rank)
        Info:SetRankDic(key)
        self:SetData(Info.allRankDic[key], v)
        -- iTrace.Log("rank = "..v.rank.."name = "..v.role_name.."score = "..v.score.."isEnd = "..msg.is_end)
    end
    self.eUpRank(Info.sRank, Info.allRankDic, Info.isEnd)
end

--响应累计获得经验
function My:RespExp(msg)
    if Info.curExp == nil then
        Info.curExp = 0
    else
        Info.curExp = msg.all_exp - Info.allExp
    end
    Info.allExp = msg.all_exp
    self.eUpExp(msg.exp)
end

--活动信息返回
function My:RespActivInfo(infoList)
    local status = infoList.status
    local endTime = infoList.end_time
	local key = tostring(infoList.id)
	if status == 2 then
		self.State = true
		local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
        local leftTime = endTime - sTime
        self.timer:Restart(leftTime, 1)
	else
        self.State = false
        Info:Clear()
    end
    self.eUpState(status)
end

--设置数据
function My:SetData(info, msg)
    info.rank = msg.rank
    info.name = msg.role_name
    info.score = msg.score
end

--判断活动是否正在开启
function My:IsOpen()
    if self.State then
        SceneMgr:ReqPreEnter(30006, true, true, true)
        return true
    end
    UITip.Log("修仙论道尚未开启")
    return false
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
    local time = self.timer.remain
	self.eUpTimer(time)
end

--结束倒计时
function My:EndCountDown()
	self.eEndTimer()
end

--清理缓存
function My:Clear()
	if self.timer then self.timer:Stop() end
end

--释放资源
function My:Dispose()
    self:RemoveLsnr()
	TableTool.ClearFieldsByName(self,"Event")
end

return My