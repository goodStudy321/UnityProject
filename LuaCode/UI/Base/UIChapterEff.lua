--region UIChapterEff.lua
--Date
--此文件由[HS]创建生成

UIChapterEff = UIBase:New{Name ="UIChapterEff"}
local M = UIChapterEff
local CMgr = ChapterMgr
local MMgr = MissionMgr

M.NextTemp = nil

function M:InitCustom()
	local name = "章节效果"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.StartRoot = T(trans, "Start")
	self.SChapterLab = C(UILabel, trans, "Start/Chapter", name, false)
	self.SStrTex = C(UITexture, trans, "Start/Str", name, false)
	self.PlayTween = C(UIPlayTween, trans, "Start", name, false)
	self.TweenAlpha = C(TweenAlpha, trans, "Start", name, false)
	self.Effect = T(trans, "Start/Chapter/FX_UI_Kaipian")

	self.CompleteRoot = T(trans, "Complete")
	self.CChapterLab = C(UILabel, trans, "Complete/Chapter", name, false)
	self.CBtn = T(trans, "Complete/Button")
	self.CGrid = C(UIGrid, trans, "Complete/Grid", name, false)

	self.CountDown = C(UILabel,trans, "Complete/Button/Timer", name, false)

	self.TimerTool = ObjPool.Get(DateTimer)
    self.TimerTool.invlCb:Add(self.InvCountDown, self)
	self.TimerTool.complete:Add(self.ClickCBtn, self)
	self.TimerTool.fmtOp = 3
	self.TimerTool.seconds = 5

	self.CItems = {}
	UITool.SetLsnrSelf(self.StartRoot, self.CloseStartRoot, self, nil, false)
	UITool.SetLsnrSelf(self.CBtn, self.ClickCBtn, self)
	self.OnPlayTweenCallback = EventDelegate.Callback(self.OnTweenFinished, self)
	EventDelegate.Add(self.PlayTween.onFinished, self.OnPlayTweenCallback)
end
--------------------------

function M:ShowStart(temp)
	if self.CompleteRoot and self.CompleteRoot.activeSelf == true then 
		self.NextTemp = temp
		return
	end
	if self.StartRoot then self.StartRoot:SetActive(true) end
	self:UpdateStartData(temp)
end

function M:ShowEnd(temp)
	self.ID = temp.id
	if self.CompleteRoot then self.CompleteRoot:SetActive(true) end
	self:UpdateCompleteData(temp)
	if self.CountDown then self.CountDown.text = "(5)" end
    self.TimerTool:Start()
end

function M:UpdateStartData(temp)
	if not temp then return end
	if self.SChapterLab then
		self.SChapterLab.text = temp.index
	end
	self.PicName = temp.strPic
	if not StrTool.IsNullOrEmpty(self.PicName) then 
		AssetMgr:Load(self.PicName,ObjHandler(self.SetStr, self))
	end
	if self.PlayTween then self.PlayTween:Play(true) end
end

function M:SetStr(tex)
	if self.SStrTex then
		self.SStrTex.mainTexture = tex
	end
end

function M:UpdateCompleteData(temp)
	if not temp then return end
	if self.CChapterLab then
		self.CChapterLab.text = temp.index
	end
	self:UpdateChapterReward(temp.items)
end

function M:UpdateChapterReward(list)
	self:ClearItems()
	local len = #list
	for i=1,len do
		local data = list[i]
		if data then
			--local go = self:AddItem(self.CGrid, self.CPrefab)
			local cell = ObjPool.Get(UIItemCell)
			cell:InitLoadPool(self.CGrid.transform)
			cell:UpData(data.id, data.val)
			table.insert(self.CItems, cell)
		end
	end
	self.CGrid:Reposition()
end

function M:AddItem(grid, prefab)
	local go = GameObject.Instantiate(prefab)
	go:SetActive(true)
	t = go.transform
	t.parent = grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	return go
end
--------------------------
function M:ClickCBtn(go)
	if self.ID then
		CMgr:ReqChapterRewardTos(self.ID)
	else
		iTrace.eError("hs", "领取章节奖励失败，没有章节ID")
	end
	if self.NextTemp then 
		if self.CompleteRoot then self.CompleteRoot:SetActive(false) end
		self:ShowStart(self.NextTemp)
		self.NextTemp = nil
		return
	end
	self:Close()
end

function M:CloseStartRoot(go)
	if self.PlayTween then self.PlayTween:Play(false) end
end

--间隔倒计时
function M:InvCountDown()
	local t = self.CountDown
	if t then t.text = string.format("(%s)", self.TimerTool.remain) end
end

function M:OnTweenFinished()
	if self.PlayTween then 
		local value = self.PlayTween.isPlayStatus
		if value == true then
			if self.Effect then self.Effect:SetActive(true) end
			if self.TweenAlpha then self.TweenAlpha.delay = 1.8 end
			self.PlayTween:Play(not value) 
		else
			self:Close()
		end
	end
end
--------------------------
function M:Update()
end

function M:OpenCustom()
	Hangup:Pause(self.Name)
end

function M:CloseCustom()
	Hangup:Resume(self.Name)
end

function M:ClearItems()
	local items = self.CItems
	if items then
		local len = #items
		while len > 0 do
			local cell = items[len]
			if cell then
				cell:Destroy()
				table.remove(items, len)
				ObjPool.Add(cell)
			end
			len = #items
		end
	end
	if self.CGrid then
		self.CGrid:GetChildList():Clear()
	end
end

function M:Clear()
	self:UnloadPic()
	self.NextTemp = nil
	if self.TimerTool then self.TimerTool:Stop() end
	self:ClearItems()
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.PicName) then
		AssetMgr:Unload(self.PicName, ".png", false)
	end
	self.PicName = nil
end

function M:DisposeCustom()
	EventDelegate.Remove(self.PlayTween.onFinished, self.OnPlayTweenCallback)
	self:Clear()
	if self.TimerTool then
		self.TimerTool:AutoToPool()
	end
	self.TimerTool = nil
end

return M

--endregion
