--[[
 	authors 	:Liu
 	date    	:2018-5-6 13:43:08
 	descrition 	:答题信息
--]]

AnswerInfo = Super:New{Name = "AnswerInfo"}

local My = AnswerInfo

function My:Init()
    --当前题目
    self.ques = 0
    --答题活动是否已结束
    self.isEnd = -1
    --当前题目的积分
    self.curScore = nil
    --当前题目的经验
    self.curExp = nil
    --题目获得的总经验
    self.allExp = 0
    --自身排行
    self.sRank = {rank = 0, name = nil, score = 0}
    --全部排行榜
    self.allRankDic = {}
    --导航目标点
    self.rPos = nil
    self.wPos = nil
end

--返回玩家的位置索引
function My:GetXPos()
    --拿到玩家的X轴
    local pPos = FindHelper.instance:GetOwnerPos()
    local posIndex = -1
    if pPos.x < 3 then
        posIndex = 1
    elseif pPos.x > 13 then
        posIndex = 0
    end
    return posIndex
end

--设置排行榜字典
function My:SetRankDic(key)
    self.allRankDic[key] = {rank = 0, name = nil, score = 0}
end

--清理缓存
function My:Clear()
    self.ques = 0
    self.isEnd = -1
    self.sRank = {}
    self.allRankDic = {}
    self.curScore = nil
    self.curExp = nil
    self.allExp = 0
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My