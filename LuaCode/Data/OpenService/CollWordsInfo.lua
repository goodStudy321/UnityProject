--[[
    集字有礼信息
]]

CollWordsInfo = Super:New{Name = "CollWordsInfo"}

local My = CollWordsInfo

--数量限制的奖励
My.countDic = {}

--奖励信息
My.AwardDic = {}

function My:Init()

end

--清理缓存
function My:Clear()
    self.countDic = {}
    self.AwardDic = {}
    TableTool.ClearUserData(self)    
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My