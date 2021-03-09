--[[
 	authors 	:Liu
 	date    	:2018-5-29 16:04:08
 	descrition 	:道庭答题信息
--]]

FamilyAnswerInfo = Super:New{Name = "FamilyAnswerInfo"}

local My = FamilyAnswerInfo

function My:Init()
    --所有道庭答题排行榜
    self.allRankDic = {}
    --自身道庭答题排行榜
    self.selfRankDic = {}
    --道庭答题活动状态
    self.activState = 0
    --判断活动是否已经结束
    self.isEnd = false
    --判断是否已经采集
    self.coll = false
end

--获取道庭答题活动状态
function My:GetActivState()
    local info = ActiveInfo["10006"]
    local hour,minute = 0
    for k,v in pairs(info.begTime) do
        hour = v.k
        minute = v.v
    end
    local state,sec = SignInfo:IsActivOpen(info.lastTime, hour, minute, true)
    if state == 1 then
        return true,sec
    else
        return false
    end
end

--设置排行榜字典
function My:SetRankDic(dic, rank1, name1, score1)
    local key = tostring(rank1)
    dic[key] = {rank = rank1, name = name1, score = score1}
end

--清理缓存
function My:Clear()
    self.allRankDic = {}
    self.selfRankDic = {}
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My