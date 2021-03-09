--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面模块2
--]]

UISuccessMod2 = Super:New{Name = "UISuccessMod2"}

local My = UISuccessMod2

require("UI/UISuccess/UISuccessMod2It")

function My:Init(root)
	local des, CG = self.Name, ComTool.Get
	local FindC, Find = TransTool.FindChild, TransTool.Find
	local str = "Scroll View"

	self.panel = CG(UIPanel, root, str)
	self.v3 = Find(root, str, des).localPosition
	self.item = FindC(root, str.."/Grid/item", des)
	self.grid = CG(UIGrid, root, str.."/Grid")
	self.parent = self.grid.transform
	self.Add = TransTool.AddChild
	self.go = root.gameObject
	self.itList = {}
	self.removeList = {}
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
	local succ = UISuccess
	succ.tab:UpTogsAction()
	for i,v in ipairs(self.itList) do
		if id == v.cfg.id then
			if v.isTop then
				self:RemoveTopIt()
				self:AddTopItem()
			else
				v:UpBtnStae()
				v:BtnSort()
			end
		end
	end
	self.grid:Reposition()
	local succ = UISuccess
    succ.mod1:UpData()
    succ.mod2:UpData(101)
	local list = succ.tab.itList
	for i,v in ipairs(list) do
		for i1, v1 in ipairs(v.grid.itList) do
			v1:UpLab()
			v1:IsShowAction()
		end
	end
	Destroy(self.removeList[1])
	table.remove(self.removeList, 1)
end

--更新数据
function My:UpData(index)
	local len = #self.itList
	local list, id = self:GetTagList(index)
	if len >= #list then self:UpState() return end
	if #list == 0 then iTrace.Error("SJ", "找不到标签类型为"..id.."的成就项") return end

	self:AddTopItem()
	for i,v in ipairs(list) do
		local it = self:AddItem(v, UISuccessMod2It, false)
		table.insert(self.itList, it)
	end
	self.item:SetActive(false)
	self.grid:Reposition()
end

--添加成就项
function My:AddItem(v, ModIt, isTop)
	local cfg = SuccessCfg
	local go = Instantiate(self.item)
	local tran = go.transform
	self.Add(self.parent, tran)
	local it = ObjPool.Get(ModIt)
	local key = tostring(v)
	it:Init(tran, cfg[key], isTop)
	it:UpData(cfg[key])
	it:UpBtnStae()
	return it
end

--添加置顶项
function My:AddTopItem()
	local topId = self:MayGetItem()
	if topId == nil then return end
	local topIt = self:AddItem(topId, UISuccessMod2It, true)
	table.insert(self.itList, 1, topIt)
	topIt.go:SetActive(true)
end

--删除置顶项
function My:RemoveTopIt()
	local list = self.itList
	local isTop = list[1].isTop
	if isTop then
		table.insert(self.removeList, list[1].go)
		list[1].go:SetActive(false)
		table.remove(self.itList, 1)
	end
end

--可领取列表
function My:MayGetItem()
	local list = SuccessInfo.getList
	if #list < 1 then return end
	table.sort(list)
	local cfg = SuccessCfg
	for i,v in ipairs(list) do
		local key = tostring(v)
		if cfg[key].succType ~= 1 then
			return v
		end
	end
end

--更新状态
function My:UpState()
	for i,v in ipairs(self.itList) do
		v:UpLab()
		v:UpBtnStae()
	end
	self:ResetPanel()
end

--重置Panel
function My:ResetPanel()
	self.panel.clipOffset = Vector2.zero
	self.panel.transform.localPosition = self.v3
end

--获取成就项数量
function My:GetTagList(index)
	local tagList = {}
	for k,v in pairs(SuccessCfg) do
		local num = math.floor(v.id / 1000)
		if num == index then
			table.insert(tagList, v.id)
		end
	end
	return tagList, index
end

--清理缓存
function My:Clear()
	self.item = nil
	self.parent = nil
	self.Add = nil
	self.grid = nil
	self.go = nil
	self.dic = nil
	self.removeList = {}
end

-- 释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
	ListTool.ClearToPool(self.itList)
end

return My