--[[
 	authors 	:Liu
 	date    	:2018-5-2 10:27:40
 	descrition 	:答题排行榜
--]]

UIAnswerRank = Super:New{Name = "UIAnswerRank"}

local My = UIAnswerRank

local RItem = require("UI/UIAnswer/UIAnswerRankIt")

function My:Init(root)
    local des, str1 = self.Name, "Scroll View/Grid"
    local CG = ComTool.Get
    UITool.SetBtnClick(root, "rankLab", des, self.OnRank, self)
    self.timerLab = CG(UILabel, root, "timerLab/lab")
    self.myScore = CG(UILabel, root, "scoreLab/lab")
    self.expLab = CG(UILabel, root, "expLab/lab")
    self.itemList = {}
    self:InitAllRank(root, str1, des)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = AnswerMgr
	mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
    mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
    mgr.eUpRank[func](mgr.eUpRank, self.RespUpRank, self)
    mgr.eUpExp[func](mgr.eUpExp, self.RespUpExp, self)
end

--响应更新倒计时
function My:RespUpTimer(time)
	self.timerLab.text = time
end

--响应结束倒计时
function My:RespEndTimer()
	self.timerLab.text = "0秒"
end

--响应更新排行榜
function My:RespUpRank(selfRank, allRankDic, endTime)
    self:UpAllRank(allRankDic)
    self.myScore.text = selfRank.score
    UIAnswer.tips:UpData()
    if endTime <= 0 then return end--答题活动结束
    self:AnswerEnd(endTime)
end

--答题活动结束
function My:AnswerEnd(endTime)
    local name = AnswerInfo.allRankDic["1"].name
    UIAnswer.abox:ActivEnd(name)
    UIAnswer.exitTip.go:SetActive(true)
    self:CreateTimer()
    local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
    local leftTime = endTime - sTime
    self.timer:Restart(leftTime, 1)
end

--响应更新经验
function My:RespUpExp(exp)
    self.expLab.text = CustomInfo:ConvertNum(exp)
end

--更新所有排行榜
function My:UpAllRank(allRankDic)
    local itemList = self.itemList
    for k,v in pairs(allRankDic) do
        if itemList[v.rank] then
            local it = itemList[v.rank]
            self:SetRankInfo(it, v)
        else
            iTrace.Error("SJ", "答题排行榜条目没有找到")
        end
    end
end

--设置排行榜信息
function My:SetRankInfo(it, v)
    it:SetRankLab(v.rank, v.name, v.score)
    it:Show()
end

--初始化所有排行榜
function My:InitAllRank(root, str1, des)
    for i=1, 3 do
        local itTran = TransTool.Find(root, str1.."/"..i, des)
        self:SetRankItem(itTran)
    end
end

--设置排行榜项
function My:SetRankItem(tran)
    local it = ObjPool.Get(RItem)
    it:Init(tran)
    table.insert(self.itemList, it)
end

--点击排行榜
function My:OnRank()
    UIAnswer.aAward.go:SetActive(true)
end

--清空排行榜
function My:ClearRank()
    local itList = self.itemList
	if #itList > 0 then
		for i,v in ipairs(itList) do
			ObjPool.Add(itList[i])
			itList[i] = nil
		end
	end
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
	UIAnswer.exitTip:UpTimeLab(self.timer.remain)
end

--结束倒计时
function My:EndCountDown()
    self:ClearTimer()
    UIAnswer.exitTip.go:SetActive(false)
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self.timerLab = nil
    self.myScore = nil
    self.expLab = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    self:ClearTimer()
    self:ClearRank()
end

return My