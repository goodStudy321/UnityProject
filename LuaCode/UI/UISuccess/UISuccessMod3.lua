--[[
 	authors 	:Liu
 	date    	:2018-9-3 12:00:00
 	descrition 	:成就界面模块3
--]]

UISuccessMod3 = Super:New{Name = "UISuccessMod3"}

local My = UISuccessMod3

require("UI/UISuccess/UISuccessMod3It")

function My:Init(root)
	local des, CG = self.Name, ComTool.Get
	local FindC, Find = TransTool.FindChild, TransTool.Find
	local str = "Scroll View"

	self.item = FindC(root, str.."/Grid/item", des)
	self.item:SetActive(false)
	self.grid = CG(UIGrid, root, str.."/Grid")
	self.sView = CG(UIScrollView, root, str)
	self.panel = CG(UIPanel, root, str)
	self.v3 = Find(root, str, des).localPosition
	self.go = root.gameObject
	self.itList = {}

	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = SuccessMgr
	mgr.eGetAward[func](mgr.eGetAward, self.RespGetAward, self)
	PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10110 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应获取奖励
function My:RespGetAward(id)
	for i,v in ipairs(self.itList) do
		if id == v.cfg.id then
			v:UpBtnStae()
			v:BtnSort()
		end
	end
	self.grid:Reposition()
	local index = SuccessInfo.togIndex
	local togsList = UISuccess.tab.itList
	if(togsList == nil) then return end
	local tog = togsList[index]
	local tog1 = togsList[1]
	if tog == nil or tog1 == nil then return end
	local list = tog.grid.itList
	local list1 = tog1.grid.itList
	for i,v in ipairs(list) do
		v:UpLab()
		v:IsShowAction()
	end
	for i,v in ipairs(list1) do
		v:IsShowAction()
	end
end

--更新成就项
function My:UpData(index)
	local item = self.item
	local Add = TransTool.AddChild
	local parent = self.grid.transform
	local len = #self.itList
	local cfg = SuccessCfg
	local list, id = self:GetTagList(cfg, index)
	if #list == 0 then
		UITip.Error("该成就暂未开放")
		iTrace.Error("SJ", "找不到标签类型为"..id.."的成就项")
		return
	end

	if #list > len then
		local num = #list - len
		for i=1, num do
			local go = Instantiate(item)
			local tran = go.transform
			Add(parent, tran)
			local it = ObjPool.Get(UISuccessMod3It)
			it:Init(tran)
			table.insert(self.itList, it)
		end
		self:UpItemData(cfg, list)
	else
		self:UpItemData(cfg, list)
	end
	self.grid:Reposition()
	self.panel.clipOffset = Vector2.zero
	self.panel.transform.localPosition = self.v3
	self.sView:ResetPosition()
end

--更新成就项数据
function My:UpItemData(cfg, list)
	for i,v in ipairs(self.itList) do
		if i > #list then
			v:Hide()
		else
			local key = tostring(list[i])
			v:UpData(cfg[key])
			v:Show()
		end
	end
end

--获取成就项数量
function My:GetTagList(cfg, index)
	local tagList = {}
	for k,v in pairs(cfg) do
		if v.tagType == index then
			table.insert(tagList, v.id)
		end
	end
	return tagList, index
end

--清理缓存
function My:Clear()
	self.dic = nil
end

-- 释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
	ListTool.ClearToPool(self.itList)
end

return My