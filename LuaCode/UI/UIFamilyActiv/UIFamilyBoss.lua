--[[
 	authors 	:Liu
 	date    	:2019-6-13 19:00:00
 	descrition 	:帮派Boss界面
--]]

UIFamilyBoss = UIBase:New{Name = "UIFamilyBoss"}

local My = UIFamilyBoss

require("UI/UIFamilyActiv/UIFamilyBossRankIt")
require("UI/UIFamilyActiv/UIFBossInspirePop")

function My:InitCustom()
	local des = self.Name
	local root = self.root
	local CG = ComTool.Get
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.itList = {}
	self.familyName = nil
	self.rank = nil
	self.joinCount = nil

	local str = "titleBg/Scroll View/Grid"
	self.exitBtn = FindC(root, "exitBtn", des)
	self.inspireBtn = FindC(root, "inspireBtn", des)
	self.inspireBg = FindC(root, "inspireBg", des)
	self.item = FindC(root, str.."/item", des)
	self.timeLab = CG(UILabel, root, "RemainTime")
	self.grid = CG(UIGrid, root, str)
	self.rankLab = CG(UILabel, root, "titleBg/Bg3/lab1")
	self.hurtLab = CG(UILabel, root, "titleBg/Bg3/lab2")
	self.joinCountLab = CG(UILabel, root, "titleBg/Bg3/lab3")
	self.inspireLab = CG(UILabel, root, "inspireBg/lab")
	self.item:SetActive(false)

	SetB(root, "inspireBtn", des, self.OnInspire, self)
	SetB(root, "exitBtn", des, self.OnExit, self)

	if ScreenMgr.orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(root, "titleBg", des, true)
	end

	self:InitRank()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = FamilyBossMgr
	mgr.eInspire[func](mgr.eInspire, self.RespInspire, self)
	mgr.eUpRank[func](mgr.eUpRank, self.RespUpRank, self)
	mgr.eEndMenu[func](mgr.eEndMenu, self.RespEndMenu, self)
	mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
	mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
	UIMainMenu.eHide[func](UIMainMenu.eHide, self.RespBtnHide, self)
	ScreenMgr.eChange[func](ScreenMgr.eChange, self.ScrChg, self)
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "titleBg", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "titleBg", nil, true, true)
	end
end

--响应更新时间
function My:RespUpTimer(time)
	local str = DateTool.FmtSec(time, 3, 1)
	self.timeLab.text = string.format("副本结束时间：%s", str)
end

--响应时间结束
function My:RespEndTimer()
	self.timeLab.gameObject:SetActive(false)
end

--响应隐藏退出按钮
function My:RespBtnHide(value)
	self.exitBtn:SetActive(value)
	self.inspireBtn:SetActive(value)
	self.inspireBg:SetActive(value)
	self.timeLab.gameObject:SetActive(value)
end

--响应鼓舞
function My:RespInspire()
	self:UpInspireLab()
	-- if self.pop then
	-- 	self.pop:UpData()
	-- end
end

--响应打开结束面板
function My:RespEndMenu(list1, list2)
	if 	self.data == nil then self.data = {} end
	self.data.award1 = list1
	self.data.award2 = list2
	self.data.rank = self.rank or 0
	self.data.joinCount = self.joinCount or 0
	UIMgr.Open(UIEndPanelT.Name, self.OpenEndPanelTCb, self)
end

--结束面板回调
function My:OpenEndPanelTCb(name)
    local ui = UIMgr.Get(name)
	if not ui then return end
	ui:UpFamilyBossData(self.data)
	ui:UpdateTimer(30)
end

--初始化排行榜
function My:InitRank()
	for i=1, 5 do
		self:SetRank()
	end
end

--更新排行榜
function My:RespUpRank(type)
	local data = FamilyBossInfo.data
	if data == nil then return end
	if type == 0 then return end
	local list = self.itList
	local rank = (type==1) and data.rank1 or data.rank2
	local num = #rank - #list
	table.sort(rank, function(a,b) return a.rank < b.rank end)

	if num > 0 then
		for i=1, num do
			self:SetRank()
        end
	end
	self:RefreshRank(rank, list)
	self.grid:Reposition()
	
	self:UpInspireLab()--更新鼓舞伤害文本
end

--设置排行榜
function My:SetRank()
	local Add = TransTool.AddChild
	local go = Instantiate(self.item)
	local tran = go.transform
	go:SetActive(true)
	Add(self.grid.transform, tran)
	local it = ObjPool.Get(UIFamilyBossRankIt)
	it:Init(tran)
	table.insert(self.itList, it)
end

--刷新排行榜
function My:RefreshRank(rank, list)
    for i,v in ipairs(rank) do
        list[i]:UpData(v.rank, v.name, v.hurtNum)
        self:UpFamilyRank(v.name, v.rank, v.hurtNum, v.joinCount)
    end
end

--更新自身道庭排行信息
function My:UpFamilyRank(name, rank, hurtNum, joinCount)
	local data = FamilyBossInfo.data
	if data == nil then return end
	if data.familyName == name then
        self:UpFamilyLabInfo(rank, hurtNum, joinCount)
    end
end

--更新道庭文本信息
function My:UpFamilyLabInfo(rank, hurtNum, joinCount)
	local hurtVal = CustomInfo:ConvertNum(tonumber(hurtNum))
	self.rankLab.text = string.format("排名：%s", rank)
	self.hurtLab.text = string.format("[C8D0E3FF]伤害：[F39800FF]%s", hurtVal)
	self.joinCountLab.text = string.format("[C8D0E3FF]参与人数：[00FF00FF]%s", joinCount)
	self.rank = rank
	self.joinCount = joinCount
end

--更新鼓舞文本
function My:UpInspireLab()
	local data = FamilyBossInfo.data
	local buffData = FamilyBossInfo.buffData
	if data == nil or buffData == nil then return end

	local val = (data.allInspire * buffData.atk) * 100
	self.inspireLab.text = string.format("道庭伤害+%s%%", val)
end

--点击鼓舞
function My:OnInspire()
	UIMgr.Open(UICopyPopup.Name, self.OpenCb, self)
end

--打开回调
function My:OpenCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpInspire()
	end
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--退出场景
function My:OnExit()
	MsgBox.ShowYesNo("是否退出场景？", self.YesCb, self)
end

--点击确定按钮
function My:YesCb()
	SceneMgr:QuitScene()
	Hangup:ClearAutoInfo()
end

--清理缓存
function My:Clear()
	self.familyName = nil
	self.rank = nil
	self.joinCount = nil
	self.data = nil
end

--重写释放资源
function My:DisposeCustom()
	self:Clear()
	ListTool.ClearToPool(self.itList)
	self:SetLnsr("Remove")
end

return My