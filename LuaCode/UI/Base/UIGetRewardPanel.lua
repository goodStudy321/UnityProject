--region UIGetRewardPanel.lua
--获得奖励
--此文件由[HS]创建生成

UIGetRewardPanel = UIBase:New{Name = "UIGetRewardPanel"}
local M = UIGetRewardPanel
local Sound = 108

M.eDoublePop = Event()

--构造函数
function M:InitCustom()
	local name = "lua获得奖励"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local str = "Scroll View/"
	local str1 = "Scroll View1/"

	self.sView = C(UIScrollView, trans, "Scroll View")
	self.bg = T(trans, "Bg")
	self.Title = T(trans, "Title")
	self.RewardG = C(UIGrid, trans, str.."Grid", name, false)
	self.RewardP = T(trans, str.."Grid/ItemCell")

	self.sView1 = C(UIScrollView, trans, "Scroll View1")
	self.RewardG1 = C(UIGrid, trans, str1.."Grid", name, false)
	self.eff = T(trans, "effs/pangkuan_ui")

	self.luckyLb = C(UILabel,trans,"luckyLb")

	self.effList = {}
	self.Rewards = {}
	self.Timer = nil

	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.bg then
		E(self.bg,self.ClickBg,self, nil, false)
	end
end

function M:RemoveEvent()
	-- body
end

function M:UpdateData(list)
	self:UpdateReward(list)
	self.Timer = Time.realtimeSinceStartup
	self.sView.gameObject:SetActive(true)
	Audio:PlayByID(Sound, 1)
	self:ReSetPanel(list)
end

-- 显示幸运值（炼丹炉用）
function M:SetLuckyLb(text)
	self.luckyLb.gameObject:SetActive(true)
	self.luckyLb.text = text
end

--更新稀有奖励数据（寻宝专用）
function M:UpRareData(list)
	self:UpdateReward(list, true)
	self.Timer = Time.realtimeSinceStartup
	self.sView1.gameObject:SetActive(true)
	Audio:PlayByID(Sound, 1)

	self:InitEffs()
	self:UpEffsPos(list)
end

--重置Panel
function M:ReSetPanel(list)
	local Pivot = UIWidget.Pivot
	self.sView.contentPivot = #list > 5 and Pivot.Top or Pivot.Center
	self.sView:ResetPosition()
end

function M:UpdateReward(list, isRare)
	if not list then return end
	local len = #list
	local sLen = #self.Rewards
	local grid = (isRare) and self.RewardG1 or self.RewardG
	self:UpdateCell(len, sLen, self.Rewards, self.RewardP, grid)
	self:UpdateCellData(self.Rewards, list)
end

function M:UpdateCell(len, sLen, list, prefab, grid)
	if sLen < len then
		for i=sLen + 1,len do
			self:AddCell(list, prefab, grid)
		end
	elseif sLen > len then
		for i= len + 1,sLen do
			self:RemoveCell(i, list)
		end
	end
	self.RewardG:Reposition()
end

function M:AddCell(list, prefab, grid)
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(grid.transform)
	table.insert(list, cell)
end

function M:RemoveCell(index, list)
	local l = #list
	while l > index do
		local cell = list[l]
		if cell then
			table.remove(list, l)
			cell:Destroy()
			ObjPool.Add(cell)
			cell = nil
		end
		l = #list
	end
end

function M:UpdateCellData(list, datas)
	local len = #datas
	for i=1,len do
		local data = datas[i]
		if data then
			local item = ItemData[tostring(data.k)]
			if item then
				local cell = list[i]
				if cell then
					cell:UpData(item,data.v)
					cell:UpBind(data.b)
				end
			end
		end
	end
end

function M:ClearItems()
	self:RemoveCell(0, self.Rewards)
end

function M:ClickBg(go)
	self:Close()
	M.eDoublePop()
end
function M:Update()
	if not self.Timer then return end
	if Time.realtimeSinceStartup - self.Timer > 10 then
		self.Timer = nil
		self:Close()
		M.eDoublePop()
	end
end

--初始化特效
function M:InitEffs()
	local Add = TransTool.AddChild
	local parent = self.eff.transform.parent
	table.insert(self.effList, self.eff)
	for i=1, 2 do
		local go = Instantiate(self.eff)
		Add(parent, go.transform)
		table.insert(self.effList, go)
	end
end

--更新特效位置
function M:UpEffsPos(list)
	if not list then return end
	local len = #list
	if len > 3 then return end
	local y = -85
	local list1 = {130}
	local list2 = {42, 215}
	local list3 = {-50, 130, 305}
	for i=1, len do
		self.effList[i]:SetActive(true)
	end
	local tran1 = self.effList[1].transform
	local tran2 = self.effList[2].transform
	local tran3 = self.effList[3].transform
	if len == #list1 then
		tran1.localPosition = Vector3(list1[1], y, 0)
	elseif len == #list2 then
		tran1.localPosition = Vector3(list2[1], y, 0)
		tran2.localPosition = Vector3(list2[2], y, 0)
	else
		tran1.localPosition = Vector3(list3[1], y, 0)
		tran2.localPosition = Vector3(list3[2], y, 0)
		tran3.localPosition = Vector3(list3[3], y, 0)
	end
end

--释放或销毁
function M:DisposeCustom()
	self:RemoveEvent()
	self:ClearItems()
	self.Rewards = nil
	self.Title = nil
	self.RewardG = nil
	self.RewardP = nil
	self.Timer = nil
end
return M
--endregion
