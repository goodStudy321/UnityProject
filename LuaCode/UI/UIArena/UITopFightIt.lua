--[[
 	authors 	:Liu
 	date    	:2018-10-23 11:09:00
 	descrition 	:青云之巅入口界面
--]]

UITopFightIt = UIBase:New{Name = "UITopFightIt"}

local My = UITopFightIt

require("UI/UIArena/UITopFightAward")

function My:InitCustom()
	local des, CG = self.Name, ComTool.Get
	local SetB, Find = UITool.SetBtnClick, TransTool.Find
	local root = self.root
	local str = "activRule/Detail/"
	local timeLab = CG(UILabel, root, str.."timeLab/lab")
	local lvLab = CG(UILabel, root, str.."lvLab")
	local desLab = CG(UILabel, root, str.."detailLab")
	local grid = Find(root, "activRule/awardLab/Grid", des)

	self.rankAward = Find(root, "RankAward", des)
	SetB(root, "activRule/EnterBtn", des, self.OnEnter, self)
	SetB(root, "activRule/hintSpr", des, self.OnHelp, self)
	SetB(root, "activRule/awardBtn", des, self.OnRankAward, self)
	SetB(root, "CloseBtn", des, self.CloseBtn, self)
	self.cellList = {}
	self:InitLab(timeLab, lvLab, desLab)
	self:InitItem(grid)
end

--初始化文本
function My:InitLab(timeLab, lvLab, desLab)
	local cfg, index = BinTool.Find(LivenessCfg, 24)
	if cfg == nil then return end
	local key = tostring(cfg.activId)
	local info = ActiveInfo[key]
	if info == nil then return end
	local day = SignInfo:GetActivTime(info.begDay)
	local time = CustomInfo:GetTimeLab(info.begTime, info.lastTime)
	timeLab.text = string.format("%s\n%s", day, time)
	lvLab.text = string.format("[F4DDBDFF]参与等级：[99886BFF]%s级", info.needLv)
	desLab.text = string.format("[F4DDBDFF]活动说明：[99886BFF]%s", cfg.des)
end

--点击进入按钮
function My:OnEnter()
	SceneMgr:ReqPreEnter(30009, true)
end

--点击帮助按钮
function My:OnHelp()
	UIComTips:Show(InvestDesCfg["5"].des, Vector3(155,-188,0))
end

--初始化显示道具
function My:InitItem(grid)
	local cfg = GlobalTemp["46"]
	if cfg == nil then return end
	local list = cfg.Value2
	if list == nil then return end
	for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(grid, 0.85)
		cell:UpData(v)
		table.insert(self.cellList, cell)
    end
end

--点击排行榜奖励
function My:OnRankAward()
	self:InitModuel()
	self.rank:UpShow(true)
end

--初始化模块
function My:InitModuel()
	if self.rank == nil then
		self.rank = ObjPool.Get(UITopFightAward)
		self.rank:Init(self.rankAward)
	end
end

--清理缓存
function My:Clear()
	
end

function My:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end
    
--释放资源
function My:DisposeCustom()
	self:Clear()
	if self.rank then
		ObjPool.Add(self.rank)
		self.rank = nil
	end
	TableTool.ClearListToPool(self.cellList)
end

return My