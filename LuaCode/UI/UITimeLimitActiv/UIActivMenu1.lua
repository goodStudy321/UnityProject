--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面1
--]]

UIActivMenu1 = Super:New{Name="UIActivMenu1"}

local My = UIActivMenu1

local strs = "UI/UITimeLimitActiv/"
require(strs.."UIRankAwardMod")
require(strs.."UIRankInfoMod")
require(strs.."UIRankInfoPop")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.modList = {}
    self.go = root.gameObject

    self.spr = CG(UISprite, root, "noticeBg/spr")
    self.spr1 = CG(UISprite, root, "noticeBg/spr1")
    self.spr2 = CG(UISprite, root, "noticeBg/spr2")
    self.lab1 = CG(UILabel, root, "noticeBg/lab")
    self.lab2 = CG(UILabel, root, "noticeBg/lab1")

    local module1 = Find(root, "module1", des)
	local module2 = Find(root, "module2", des)
    local module3 = Find(root, "RankAward", des)
    self:InitModule(module1, UIRankAwardMod)
    self:InitModule(module2, UIRankInfoMod)
    self:InitModule(module3, UIRankInfoPop)

    SetB(root, "rankBtn", des, self.OnRank, self)

    self:InitTexInfo()
    self:CreateTimer()
    self:InitTimeLab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = TimeLimitActivMgr
    mgr.eRankInfo[func](mgr.eRankInfo, self.UpRankInfo, self)
    -- FightVal.eChgFv[func](FightVal.eChgFv, self.RespUpFight, self)
end

-- --响应更新战力
-- function My:RespUpFight()

-- end

--更新排行榜信息
function My:UpRankInfo()
    self.modList[2]:UpMiniRank()
    self.modList[3]:UpRankInfo()
end

--初始化模块
function My:InitModule(module, class)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    table.insert(self.modList, mod)
end

--初始化展示图片信息
function My:InitTexInfo()
    self.color = ""
    local str1 = "CB_1_AD11"
    local info = TimeLimitActivInfo
    local idList = info.idList
    local type = info:GetOpenType()
    if type == idList[1] then
        self.spr.spriteName = "CB_1_AD2"
        self.color = "[2B1765FF]"
        str1 = "CB_1_AD22"
    elseif type == idList[2] then
        self.spr.spriteName = "CB_1_AD1"
        self.color = "[36312BFF]"
        str1 = "CB_1_AD11"
    elseif type == idList[3] then
        self.spr.spriteName = "CB_1_AD3"
        self:ChangeLabPos()
        self.color = "[D7CBB3FF]"
        str1 = "CB_1_AD33"
    end
    self.spr1.spriteName = str1
    self.spr2.spriteName = str1
    self.lab2.text = string.format("%s活动截止时间点为23点,请提前1小时冲榜！", self.color)
end

--改变文本位置
function My:ChangeLabPos()
    local lab1 = self.lab1.transform
    local lab2 = self.lab2.transform
    local pos1 = lab1.localPosition
    local pos2 = lab2.localPosition
    local info = TimeLimitActivInfo
    local type=TimeLimitActivMgr.type
    local xPos = (info.isLastDayDic[tostring(type)]==1) and 33 or pos1.x
    lab1.localPosition = Vector3(xPos, pos1.y-10, 0)
    lab2.localPosition = Vector3(pos2.x, pos2.y-10, 0)
end

--初始化时间文本
function My:InitTimeLab()
    local info = TimeLimitActivInfo
    local type = info:GetActivType()
    local isOpen = LivenessInfo:IsOpen(type)
    if isOpen then
        local data = LivenessInfo.xsActivInfo[tostring(type)]
        local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
        local leftTime = data.eTime - sTime
        local dayTime = 24*60*60
        local temp = leftTime - dayTime
        local num = (temp<0) and 0 or temp
        self:UpTimer(num)
    end
end

--点击排行榜
function My:OnRank()
    self.modList[3]:UpShow(true)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
    timer:Start()
    self:InvCountDown()
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
    local remain = self.timer.remain
	self.lab1.text = string.format("%s活动倒计时:[E5B45FFF]%s", self.color, remain)
    UITimeLimitActiv.eUpTimer(remain)
end

--结束倒计时
function My:EndCountDown()
    self.lab1.text = string.format("%s活动已结束", self.color)
    self.lab2.gameObject:SetActive(false)
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
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:ClearTimer()
    TableTool.ClearDicToPool(self.modList)
    self.modList = nil
    self:SetLnsr("Remove")
end

return My