--[[
 	authors 	:Liu
 	date    	:2019-6-11 20:10:00
 	descrition 	:道庭Boss
--]]

UIFamilyBossIt = UIBase:New{Name = "UIFamilyBossIt"}

local My = UIFamilyBossIt

local str = "UI/UIFamilyActiv/"
require(str.."UIFamilyBossTog")
require(str.."UIFBossTogRank")

function My:InitCustom()
	local des = self.Name
	local root = self.root
	local CG = ComTool.Get
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.itList = {}
	self.cellList = {}
	self.needLv = nil
	self.mCfg = nil
	self.curCfg = nil
	self.curIndex = nil

	self.item = FindC(root, "BossBtns/Grid/item", des)
	self.rankTran = Find(root, "rankBg", des)
	self.grid = CG(UIGrid, root, "BossBtns/Grid")
	self.cellGrid = CG(UIGrid, root, "Scroll View2/Grid")
	-- self.Action = FindC(root, "enterBtn/Action", des)

	SetB(root, "enterBtn", des, self.OnEnter, self)
	SetB(root, "CloseBtn", des, self.OnClose, self)
	SetB(root, "bg/tipSpr", des, self.OnTips, self)

	self:InitCfg()
    if self.mCfg == nil or self.curCfg == nil then return end

	self:SetLnsr("Add")
	EventMgr.Add("QuitFamily", function () self:RespQuitFamily() end)
	FamilyBossMgr:ReqInfo()
end

--设置监听
function My:SetLnsr(func)
	local mgr = FamilyBossMgr
	mgr.eUpMenu[func](mgr.eUpMenu, self.RespUpMenu, self)
	mgr.eUpMenuRank[func](mgr.eUpMenuRank, self.RespUpRank, self)
end

--响应更新界面
function My:RespUpMenu(type)
	self:InitBossItem()
	self:InitCell()
	-- self:UpAction()

	local num = tonumber(type)
	if num ~= 0 and self.itList[num] then
		self.itList[num]:UpAction()
	end
end

--响应更新排行榜
function My:RespUpRank(type)
	self:UpRankModule(type)
end

--响应解散道庭
function My:RespQuitFamily()
	self:Close()
end

--初始化显示道具
function My:InitCell()
	local list = self.curCfg.award
	local limit = math.ceil(#list / 3)
	self.cellGrid.maxPerLine = limit

	for i,v in ipairs(list) do
		local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.cellGrid.transform, 0.8)
        cell:UpData(v)
        table.insert(self.cellList, cell)
	end
	self.cellGrid:Reposition()
end

--初始化配置
function My:InitCfg()
    local curCfg = FamilyBossInfo:GetCurCfg()
    local mCfg = MonsterTemp[tostring(curCfg.monsterId)]
	self.mCfg = mCfg
	self.curCfg = curCfg
end

--初始化Boss项
function My:InitBossItem()
	local cfg = ActiveInfo["10012"]
	if cfg == nil then return end
	self.needLv = cfg.needLv

	local SetS = UITool.SetLsnrSelf
	local AddC = TransTool.AddChild
	local parent = self.item.transform.parent
	for i,v in ipairs(cfg.begTime) do
		local go = Instantiate(self.item)
		local tran = go.transform
		go.name = i + 100
		AddC(parent, tran)
		local it = ObjPool.Get(UIFamilyBossTog)
        it:Init(tran, v, cfg.lastTime, self.mCfg, i)
		table.insert(self.itList, it)
		SetS(tran, self.OnTog, self, self.Name)
	end
	self.item:SetActive(false)
	self.grid:Reposition()

	local index = self:GetLightIndex()
	self:UpTogs(index)
end

--更新Tog
function My:UpTogs(index)
	for i,v in ipairs(self.itList) do
		v:UpState(index==i)
	end
	self.curIndex = index
end

--点击Tog
function My:OnTog(go)
	local index = tonumber(go.name) - 100
	self:UpTogs(index)
end

--更新排行榜模块
function My:UpRankModule(type)
	if self.rank == nil then
		self.rank = ObjPool.Get(UIFBossTogRank)
		self.rank:Init(self.rankTran, type)
	end
	self.rank:Open(type)
end

--点击进入按钮
function My:OnEnter()
	if self.curIndex then
		if self:IsKill(self.curIndex) then
			UITip.Log("BOSS已被击败")
			return
		end
		if self:IsEnter(self.curIndex) == false then
			UITip.Log("活动未开启")
			return
		end
	end
	if CustomInfo:IsOpen(10012) == false then return end
	if FamilyBossMgr.State then
		SceneMgr:ReqPreEnter(30004, true, true)
	else
		UITip.Log("活动未开启")
	end
end

--是否已击败
function My:IsKill(type)
	local data = FamilyBossInfo.data
	local value = (type==1) and data.hpValue1 or data.hpValue2
	if value <= 0 then
		return true
	end
	return false
end

--是否能进入
function My:IsEnter(index)
	local data = FamilyBossInfo.data
	if data.type == index then
		return true
	end
	return false
end

--获取高亮按钮索引
function My:GetLightIndex()
	for i,v in ipairs(self.itList) do
		if self:IsEnter(i) then return i end
		if self:IsKill(i) == false then return i end
	end
	return 1
end

--点击提示
function My:OnTips()
	local cfg = InvestDesCfg["1033"]
    if cfg == nil then return end
    UIComTips:Show(cfg.des, Vector3(-67, -160, 0))
end

-- --更新红点
-- function My:UpAction()
-- 	self.Action:SetActive(FamilyBossMgr.State)
-- end

--打开（关闭时直接关闭）
function My:OpenTab(isRecord)
	self.isRecord = isRecord
	UIMgr.Open(UIFamilyBossIt.Name)
end

--点击关闭按钮
function My:OnClose()
	if self.isRecord == true then
		self:Close()
		JumpMgr.eOpenJump()
	else
		self:Close()
		UIMgr.Open(UIFamilyMainWnd.Name, self.OpenFamilyCb, self)
	end
end

--打开仙盟回调
function My:OpenFamilyCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:ChangePanel(3)
	end
end

--特殊的开启条件
function My:GetSpecial()
	return CustomInfo:IsJoinFamily()
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
	
end

--清理缓存
function My:Clear()
	self.mCfg = nil
	self.curCfg = nil
	self.isRecord = nil
	self.curIndex = nil
	if self.rank then
		ObjPool.Add(self.rank)
		self.rank = nil
	end
end

--释放资源
function My:DisposeCustom()
	self:Clear()
	ListTool.ClearToPool(self.itList)
	TableTool.ClearListToPool(self.cellList)
	self:SetLnsr("Remove")
	EventMgr.Remove("QuitFamily", function () self:RespQuitFamily() end)
end

return My