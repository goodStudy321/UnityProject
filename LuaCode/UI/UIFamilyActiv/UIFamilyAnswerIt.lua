--[[
 	authors 	:Liu
 	date    	:2018-4-11 09:09:00
 	descrition 	:道庭答题入口界面
--]]

UIFamilyAnswerIt = UIBase:New{Name = "UIFamilyAnswerIt"}

local My = UIFamilyAnswerIt

function My:InitCustom()
	local des, CG = self.Name, ComTool.Get
	local SetB, Find = UITool.SetBtnClick, TransTool.Find
	local root = self.root
	local str = "activRule/Detail/"
	local timeLab = CG(UILabel, root, str.."timeLab/lab")
	local lvLab = CG(UILabel, root, str.."lvLab")
	local desLab = CG(UILabel, root, str.."detailLab")
	local grid = Find(root, "activRule/awardLab/Grid", des)

	SetB(root, "activRule/EnterBtn", des, self.OnEnter, self)
	SetB(root, "activRule/hintSpr", des, self.OnHelp, self)
	SetB(root, "CloseBtn", des, self.OnClose, self)
	self.cellList = {}
	self:InitLab(timeLab, lvLab, desLab)
	self:InitItem(grid)
end

--初始化文本
function My:InitLab(timeLab, lvLab, desLab)
	local cfg, index = BinTool.Find(LivenessCfg, 11)
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
	if CustomInfo:IsOpen(10006) == false then return end
	local isOpen = (FamilyAnswerInfo.activState == 2) and true or false
	if isOpen then
		local ui = UIMgr.Get(UISystem.Name)
		if ui then ui:Close() end
		SceneMgr:ReqPreEnter(30007, true, true)
	else
		UITip.Error("活动尚未开启")
	end
end

--点击帮助按钮
function My:OnHelp()
	UIComTips:Show(InvestDesCfg["4"].des, Vector3(155,-188,0))
end

--初始化显示道具
function My:InitItem(grid)
	local cfg = GlobalTemp["45"]
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

--点击关闭
function My:OnClose()
	UIMgr.Open(UIFamilyMainWnd.Name, self.OpenFamilyCb, self)
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
	
end
    
--释放资源
function My:DisposeCustom()
	self:Clear()
	TableTool.ClearListToPool(self.cellList)
end

return My