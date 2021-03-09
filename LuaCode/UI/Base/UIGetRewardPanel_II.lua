--region UIGetRewardPanel.lua
--护送奖励
--此文件由[HS]创建生成

UIGetRewardPanel_II = UIBase:New{Name = "UIGetRewardPanel_II"}
local M = UIGetRewardPanel_II
local eMgr = EscortMgr
local Sound = 108
M.Escort = 1
--构造函数
function M:InitCustom()
	local name = "lua获得奖励"
	local go = self.gbj
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	local str = "Scroll View/"
	self.OkBtn = T(trans, "OK")
	self.CloseBtn = T(trans, "Close")
	self.ContinueBtn = T(trans, "Continue")
	self.Timer = C(UILabel, trans, "Continue/Timer")
	self.Rate = C(UILabel, trans, "Rate", name, false)
	self.IsEnd = C(UILabel, trans, "IsEnd", name, false)
	self.RewardG = C(UIGrid, trans, str.."Grid", name, false)
	self.RewardP = T(trans, str.."Grid/ItemCell")
	self.Rewards = {}
	self.TimerTool = ObjPool.Get(DateTimer)
    self.TimerTool.invlCb:Add(self.InvDownCount, self)
	self.TimerTool.complete:Add(self.CompleteDownCount, self)
	self.TimerTool.fmtOp = 3
	self.TimerTool.seconds = 5
	self.Type = nil
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.OkBtn then
		E(self.OkBtn,self.Close,self)
	end
	if self.CloseBtn then
		E(self.CloseBtn,self.Close,self)
	end
	if self.ContinueBtn then
		E(self.ContinueBtn,self.ClickContinueBtn,self, nil, false)
	end
end

function M:RemoveEvent()
	-- body
end

function M:UpdateData(list, type)
	self.Type = type
	self:UpdateBtns()
	self:UpdateReward(list)
	Audio:PlayByID(Sound, 1)
	self:UpdateRate()
	self:UpdateIsEnd()
	self.TimerTool:Start()
end

function M:UpdateBtns()
	local active = true
	if self.Type == self.Escort then
		active = eMgr.Num <= 0
	end
	if self.OkBtn then self.OkBtn:SetActive(active) end
	if self.CloseBtn then self.CloseBtn:SetActive(not active) end
	if self.ContinueBtn then self.ContinueBtn:SetActive(not active) end
end

function M:UpdateReward(list)
	if not list then return end
	local len = #list
	local sLen = #self.Rewards
	self:UpdateCell(len, sLen, self.Rewards, self.RewardP, self.RewardG)
	self:UpdateCellData(self.Rewards, list)
end

function M:UpdateRate()
	if self.Rate then
		local active = self.Type == self.Escort
		local double = false
		local rate = "100%"
		local active = false
		local data = LivenessInfo:GetActInfoById(1012)
		if data then 
			active = data.val == 1
		end
		if active == true then
			rate = "200%"
		end
		self.Rate.gameObject:SetActive(active == true )
		self.Rate.text = rate
	end
end

function M:UpdateIsEnd()
	if self.IsEnd then
		local active = self.Type == self.Escort and eMgr.Num == 0
		local txt = string.format("还有[00ff00]%s[-]次护送机会", eMgr.Num)
		if active == true then txt = "今天的护送任务已全部完成，请明天再来" end
		self.IsEnd.text = txt
	end
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

--间隔倒计时
function M:InvDownCount()
	local t = self.Timer
	local tool = self.TimerTool 
	if t and tool then 
		t.text = string.format("(%s)", tool.remain) 
	end
end

--间隔倒计时
function M:CompleteDownCount()
	if self.ContinueBtn.activeSelf == true then
		self:ClickContinueBtn()
	else
		self:Close()
	end
end

function M:ClearItems()
	self:RemoveCell(0, self.Rewards)
end

function M:ClickBg(go)
	if self.Type then return end
	self:Close()
end

function M:ClickContinueBtn(go)
	if self.Type == self.Escort then
		if eMgr.Num > 0 then
			EscortMgr:NavEscort()
		end
	end
	self:Close()
end

function M:CloseCustom()
	if self.TimerTool then self.TimerTool:Stop() end
end

--释放或销毁
function M:DisposeCustom()
	self:RemoveEvent()
	self:ClearItems()
	self.Rewards = nil
	if self.TimerTool then
		self.TimerTool:AutoToPool()
	end
	self.TimerTool = nil
	TableTool.ClearUserData(self)
end
return M
--endregion
