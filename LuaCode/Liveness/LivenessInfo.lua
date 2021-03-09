--[[
 	authors 	:Liu
 	date    	:2018-4-13 16:48:08
 	descrition 	:活跃度信息
--]]

LivenessInfo = Super:New{Name = "LivenessInfo"}

local My = LivenessInfo

--字符串列表
My.strTab = {Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6, Sunday=7}
--活跃度
My.liveness = 0
--活动项次数字典
My.countDic = {}
--已领取的奖励字典
My.awardDic = {}
--当前选中的活动项
My.btnIndex = 1
--限时活动信息字典
My.xsActivInfo = {}
--自定义表
My.tab = {id = nil, val = nil, sTime = nil, eTime = nil, visible = nil, sDate = nil, eDate = nil}
--可以领取的奖励
My.getsList = {}

My.xsActivInfo["1018"] = {id = 1018, val = 0}--开服活动容器
My.KFHD = {1003, 1005, 1016, 1017, 1019, 1022, 1036}

My.xsActivInfo["1032"] = {id = 1032, val = 0}--仙途之路容器
My.XTZL = {1029, 1034, 1035}

function My:Init()
    for i, v in ipairs(LivenessCfg) do
        local id = tostring(v.id)
        self.countDic[id] = 0
    end
end

--设置限时活动信息
function My:SetXsActivInfo(id, val, startTime, endTime, visible, sDate, eDate)
    self.tab = {id = id, val = val, sTime = startTime, eTime = endTime, visible = visible, sDate = sDate, eDate = eDate}
    local key = tostring(id)
    self.xsActivInfo[key] = self.tab
    self:UpdateActiv(self.KFHD, "1018")
    self:UpdateActiv(self.XTZL, "1032")
end

--更新活动容器
function My:UpdateActiv(list, key)
    local len = #list
    local val = 0
    for i=1,len do
        if self:IsOpen(list[i]) then
            val = 1
            break
        end
    end
    self.xsActivInfo[key].val = val
end

function My:IsOpen(id)
    local t = self:GetActInfoById(id)
    return t and t.val == 1
end

function My:GetActInfoById(id)
    local key = tostring(id)
    if not self.xsActivInfo[key] then return false end
    return self.xsActivInfo[key]
end

--移除活动信息
function My:RemoveActInfo(id)
    local key = tostring(id)
    if self.xsActivInfo[key] then
        self.xsActivInfo[key] = false
        return false
    end
    return true
end

--清理缓存
function My:Clear()
    self.liveness = 0
    self.btnIndex = 1
    ListTool.Clear(self.getsList)
    TableTool.ClearDic(self.countDic)
    TableTool.ClearDic(self.awardDic)
    TableTool.ClearDic(self.xsActivInfo)
    self.xsActivInfo["1018"] = {id = 1018, val = 0}
    self.xsActivInfo["1032"] = {id = 1032, val = 0}
end

--释放资源(整个游戏退出时调用，以形式存在)
function My:Dispose()
    self:Clear()
end

return My