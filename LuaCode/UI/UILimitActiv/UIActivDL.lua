--[[
 	authors 	:Liu
 	date    	:2019-06-28 15:00:00
 	descrition 	:材料掉落
--]]

UIActivDL = Super:New{Name = "UIActivDL"}

local My = UIActivDL

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find

	self.go = root.gameObject

	self.desLab = CG(UILabel, root, "Des2")
	self.countDown = CG(UILabel, root, "Countdown")
	self.gridTran = Find(root, "Des2/ItemRoot/Grid")

	self:UpActTime()
	self:InitCell()
	self:InitDes()
end

--初始化道具
function My:InitCell()
	local cfg = GlobalTemp["155"]
	if cfg == nil then return end
	self.cell = ObjPool.Get(UIItemCell)
	self.cell:InitLoadPool(self.gridTran)
	self.cell:UpData(cfg.Value3)
end

--初始化描述文本
function My:InitDes()
    local info = LivenessInfo:GetActInfoById(1034)
    if info == false then return end
    local DateTime = System.DateTime
    local sTime = DateTime.Parse(tostring(DateTool.GetDate(info.sTime))):ToString("yyyy年MM月dd日hh:mm")
    local eTime = DateTime.Parse(tostring(DateTool.GetDate(info.eTime))):ToString("yyyy年MM月dd日hh:mm")
	local cfg = InvestDesCfg["18"]
	if cfg == nil then return end
    self.desLab.text = string.format("[581f2a]活动时间：%s-%s\n[-]%s", sTime, eTime, cfg.des)
end

--更新活动时间
function My:UpActTime()
    local info = LivenessInfo:GetActInfoById(1034)
    if info == false then return end
    local eDate = info.eTime
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清空道具
function My:ClearCell()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
	self:ClearCell()
    self:ClearTimer()
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My