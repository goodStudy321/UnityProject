--[[
 	authors 	:Liu
 	date    	:2018-12-17 17:00:00
 	descrition 	:宴会信息弹窗
--]]

UIFeastInfoPop = Super:New{Name = "UIFeastInfoPop"}

local My = UIFeastInfoPop

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.btnBox = CG(BoxCollider, root, "bg/btn1")
	self.name1 = CG(UILabel, root, "bg/texBg1/lab")
	self.name2 = CG(UILabel, root, "bg/texBg2/lab")
	self.lab1 = CG(UILabel, root, "bg/labBg/lab1")
	self.lab2 = CG(UILabel, root, "bg/labBg/lab2")
	self.btnLab = CG(UILabel, root, "bg/btn1/lab")
	self.btn3 = FindC(root, "bg/btn3", des)
	self.action = FindC(root, "bg/btn1/action", des)
	self.go = root.gameObject
	self.isClick = false
	self.times = 0
	self.openStr = ""
	SetB(root, "bg/btn1", des, self.OnBtn1, self)
	SetB(root, "bg/btn2", des, self.OnBtn2, self)
	SetB(root, "bg/btn3", des, self.OnBtn3, self)
	SetB(root, "bg/close", des, self.OnClose, self)
	self:CreateTimer()
	self:InitData()
	self:InitNameLab()
	self:InitFeastTime()
	self:UpRTime()
	self:InitBtnLab()
	self:InitBtnState()
	self:UpAction()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.eFeastState[func](MarryMgr.eFeastState, self.RespFeastState, self)
	MarryMgr.eApplyGuest[func](MarryMgr.eApplyGuest, self.RespApplyGueste, self)
	MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
	MarryMgr.ePopCancel[func](MarryMgr.ePopCancel, self.RespPopCancel, self)
	MarryMgr.eUpAction[func](MarryMgr.eUpAction, self.RespUpAction, self)
end

--响应更新红点
function My:RespUpAction()
    self:UpAction()
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
    if not isAllShow and self.go.activeSelf then
       	local info = MarryInfo
		local count = info:GetInviteBuy()
		if info:IsSucc(count) then
			MarryMgr:ReqBuyJoin()
		else
			if self.isJump == nil then
				UIMgr.Open(UIMarryPop.Name, self.OpenPop1, self)
				self.isJump = true
			elseif self.isJump then
				VIPMgr.OpenVIP(1)
				self.isJump = nil
			end
		end
    end
end

--响应弹窗点击取消
function My:RespPopCancel(isAllShow)
	if not isAllShow and self.go.activeSelf then
		self.isJump = nil
	end
end

--响应宾客邀请
function My:RespApplyGueste()
	local isRole = self:IsFeastRole()
	if isRole == nil then return end
	if isRole then
		UIProposePop.modList[5]:AddInviteList()
	else
		UITip.Log("申请成功")
	end
end

--响应婚宴状态
function My:RespFeastState(state)
	if state then
		self:UpRTime()
	end
end

--初始化名字文本
function My:InitNameLab()
	local str1 = ""
	local str2 = ""
	if self.data1 and self.data2 then
		if self.data1.sex == 0 then
			str1 = self.data2.name
			str2 = self.data1.name
		else
			str1 = self.data1.name
			str2 = self.data2.name
		end
	elseif self.data then
		if self.data.sex == 0 then
			str1 = self.data.name
			str2 = User.MapData.Name
		else
			str1 = User.MapData.Name
			str2 = self.data.name
		end
	else
		return
	end
	self.name1.text = str1
	self.name2.text = str2
	local str3 = string.format("[88F8FFFF]%s[FFE9BDFF]与[88F8FFFF]%s[FFE9BDFF]在万仙城举办豪华婚礼", str1, str2)
	self.lab1.text = str3
end

--初始化婚礼举办者数据
function My:InitData()
	local info = MarryInfo
	self.data = info.data.coupleInfo
	if info.feastData.feastState ~= 0 then
		self.data1 = info.feastData.role1
		self.data2 = info.feastData.role2
	end
end

--点击关闭
function My:OnClose()
    local it = UIProposePop
    it:Close()
    it:ResetState()
end

--初始化婚宴开始时间
function My:InitFeastTime()
	local info = MarryInfo
	local endTime = self:GetEndTime()
	if endTime > 0 then
		local month = info:GetDate(endTime, "MM")
		local day = info:GetDate(endTime, "dd")
		local hour = info:GetDate(endTime, "HH")
		local minute = info:GetDate(endTime, "mm")
		local min = (minute < 10) and "0"..minute or minute
		local hours = (hour < 10) and "0"..hour or hour
		local str = string.format("[FFE9BDFF]婚宴时间：[88F8FFFF]%s月%s日%s:%s", month, day, hours, min)
		self.lab2.text = str
		self.str = str
	end
end

--更新宴会的剩余时间
function My:UpRTime()
	local endTime = self:GetEndTime()
	if endTime > 0 then
		local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
		local leftTime = endTime - sTime
		self:UpTimer(leftTime)
	end
end

--更新计时器
function My:UpTimer(rTime)
	if self.timer == nil then return end
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
	timer:Start()
	self:InvCountDown()
end

--获取宴会结束时间
function My:GetEndTime()
	local endTime = 0
	local info = MarryInfo.feastData
	if self.data1 and self.data2 then
		endTime = info.endTime
	elseif self.data then
		endTime = info.feastTime
	end
	return endTime
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
	if self.lab2 and self.str then
		local info = MarryInfo.feastData
		local temp = (info.feastState == 2) and "结束" or "开始"
		local times = self.timer:GetRestTime()
		local timeStr = self.timer.remain
		local str = string.format("%s（%s后%s）", self.str, timeStr, temp)
        self.lab2.text = str
	end
	--点击间隔
	local time = self.timer:GetRestTime()
	time = math.floor(time)
	if self.isClick then
		self.times = time
		self.isClick = false
	end
	if (self.times - time) > 1 then
		self.times = 0
		self.btnBox.enabled = true
	end
end

--结束倒计时
function My:EndCountDown()
	local state = MarryInfo.feastData.feastState
	if state == 0 then
		local str = string.format("%s（婚宴已结束）", self.str)
        self.lab2.text = str
	end
end

--点击宾客管理
function My:OnBtn1()
	local isRole = self:IsFeastRole()
	if isRole or isRole == nil then
		UIProposePop:SetMenuState(6)
	else
		MarryMgr:ReqApplyGuest()
		self.btnBox.enabled = false
		self.isClick = true
	end
end

--点击参加婚宴
function My:OnBtn2()
	local state = MarryInfo.feastData.feastState
	if state == 2 then
		if SceneMgr:IsChangeScene() == true then
			SceneMgr:ReqPreEnter(30019, true, true)
		end
	else
		UITip.Log("婚宴尚未开始")
	end
end

--点击购买请帖
function My:OnBtn3()
	-- if MarryInfo:IsInvite() then UITip.Log("您已在宾客列表中") return end
	local count = MarryInfo:GetInviteBuy()
	self.openStr = string.format("是否花费%s绑元购买喜帖？\n(绑元不足消耗元宝)", count)
	UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel(self.openStr)
    end
end

--打开弹窗
function My:OpenPop1()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
		ui:UpPanel("元宝不足，是否充值？")
    end
end

--设置购买请帖按钮状态
function My:InitBtnState()
	-- if MarryInfo:IsAppoint() then
	-- 	self.btn3:SetActive(false)
	-- end
	local str = self.btnLab.text
	if str == "管理宾客" then
		self.btn3:SetActive(false)
	end
end

--初始化按钮文本
function My:InitBtnLab()
	local isRole = self:IsFeastRole()
	if isRole == nil then return end
	if isRole then
		self.btnLab.text = "管理宾客"
	else
		self.btnLab.text = "索要请帖"
	end
end

--判断是否是宴会举办者
function My:IsFeastRole()
	if self.data1 and self.data2 then
		return MarryInfo:IsFeastRole()
	end
	return nil
end

--更新红点
function My:UpAction()
	self.action:SetActive(MarryInfo.isShowAction)
end

--清理缓存
function My:Clear()
	self.data = nil
	self.data1 = nil
	self.data2 = nil
	self.isClick = false
	self.times = 0
	self.openStr = ""
end
	
--释放资源
function My:Dispose()
	self:Clear()
	if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
	end
	self:SetLnsr("Remove")
end
	
return My