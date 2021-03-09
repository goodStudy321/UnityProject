--region UIChapterPanel.lua
--Date
--此文件由[HS]创建生成

UIChapterPanel = UIBase:New{Name ="UIChapterPanel"}
local M = UIChapterPanel
local CMgr = ChapterMgr
local MMgr = MissionMgr

function M:InitCustom()
	local name = "章节面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.CloseBtn = T(trans, "Close")
	self.ReceiveBtn = C(UIButton, trans, "ReceiveBtn", name, false)
	self.ReceiveLab = C(UILabel, trans, "ReceiveBtn/Label", name, false)
	self.ExecuteBtn = C(UIButton, trans, "ExecuteBtn", name, false)

	self.ScrollView = C(UIScrollView, trans, "Scroll View", name, false)
	self.Grid = C(UIGrid, trans, "Scroll View/Grid", name, false)
	self.Prefab = T(trans, "Scroll View/Grid/Item")

	self.Des = C(UILabel, trans, "Des", name, false)
	self.Title = C(UILabel, trans, "Title", name, false)
	self.Progress = C(UILabel, trans, "Progress", name, false)
	self.Slider = C(UISlider, trans, "Slider", name, false)
	self.CReward = C(UIGrid, trans, "CReward", name, false)
	--self.CPrefab = T(trans, "CReward/ItemCell")

	self.Interactive = C(UILabel, trans, "Interactive", name, false)
	self.Target = C(UILabel, trans, "Target", name, false)
	self.MReward = C(UIGrid, trans, "MReward", name, false)
	self.MPrefab = T(trans, "MReward/ItemCell")
	self:InitData()
end

function M:InitData()
	self.ChapterList = {}
	self.CItems = {}
	self.MItems = {}
	for i,v in ipairs(ChapterTemp) do
		local data = self:AddChapter(i, v)
		self:UpdateChapter(data)
		table.insert(self.ChapterList, data)
	end
	self.Grid:Reposition()
end

function M:AddEvent()
	self:UpdateEvent(EventMgr.Add)
	self:SetEvent("Add")
	local E = UITool.SetLsnrSelf
	if self.CloseBtn then
		E(self.CloseBtn, self.CloseClick, self)
	end
	if self.ReceiveBtn then
		E(self.ReceiveBtn, self.ClickReceiveBtn, self)
	end
	if self.ExecuteBtn then
		E(self.ExecuteBtn, self.ClickExecuteBtn, self)
	end
	if self.ChapterList then
		local len = #self.ChapterList
		for i=1, len do
			E(self.ChapterList[i].Root, self.OnClickChapter, self, nil, false)
		end
	end
end

function M:RemoveEvent()
	self:UpdateEvent(EventMgr.Remove)
	self:SetEvent("Remove")
end

function M:UpdateEvent(M)	
end

function M:SetEvent(fn)
	MMgr.eEndUpdateMission[fn](MMgr.eEndUpdateMission, self.UpdateMainMission, self)
	CMgr.UpdateChapter[fn](CMgr.UpdateChapter, self.UpdateChapterInit, self)
end

-------------------------------------------------------------------------
function M:AddChapter(index, temp)
	local go = GameObject.Instantiate(self.Prefab)
	local t = go.transform
	t.parent = self.Prefab.transform.parent
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	go:SetActive(true)
	go.name = tostring(index)
	local C = ComTool.Get
	local data = {}
	data.Root = go
	data.Temp = temp
	data.Toggle = go:GetComponent(typeof(UIToggle))
	local name = temp.name
	data.BG = C(UISprite, t, "Background", name, false)
	data.Label = C(UILabel, t, "Label", name, false)
	data.Pic = C(UITexture, t, "Pic", name, false)
	data.IsEnd = TransTool.FindChild(t, "IsEnd")
	data.Lock = TransTool.FindChild(t, "Lock")
	return data
end

function M:UpdateChapter(data)
	local temp = data.Temp
	local toggle = data.Toggle
	local label = data.Label
	local pic = data.Pic
	local IsEnd = data.IsEnd
	if not temp then return end
	if toggle then
		toggle:IsEnabled(false, true, Color.white)
	end
	if label then
		label.text = string.format("%s %s", temp.index ,temp.name )
	end
	if pic then
		if not StrTool.IsNullOrEmpty(temp.pic) then	
			self.PicName = temp.pic
			local del = ObjPool.Get(DelLoadTex)
			del:Add(pic)
			del:SetFunc(self.SetChapterIcon,self)
			AssetMgr:Load(temp.pic,ObjHandler(del.Execute, del))
			return
		end
	end
end

function M:SetChapterIcon(tex, pic)
	if pic then
		pic.mainTexture = tex
	end
end

function M:OnClickChapter(go)
	local name = go.name
	local index = tonumber(name)
	local len = #self.ChapterList
	if index > len then return end
	local data = self.ChapterList[index] 
	if not data then return end
	self:UpdateChapterData(data.Temp)
end
-------------------------------------------------------------------------

function M:UpdateChapterData(data)
	self:ClearChapter()
	if not data then return end
	self.Data = data
	self:UpdateDes(data.des)
	self:UpdateProgress(data.id, data.limit)
	self:UpdateChapterReward(data.items)
end

function M:UpdateDes(des)
	if self.Des then
		self.Des.text = des
	end
end

function M:UpdateProgress(id, limit)
	local num = 0
	local state = false
	local receive = "已领取"
	local data = CMgr.ChapterDic[tostring(id)]
	if data then 
		num = data.Num
		state = data.IsReward
	 end
	if not num then num = 0 end
	if self.Progress then
		self.Progress.text = string.format("（%s/%s）",num, limit)
	end
	if self.Slider then
		self.Slider.value = num / limit
	end
	if state == false then
		if num < limit then
			receive = "未达成"
		else
			receive = "可领取"
		end
	end
	if self.ReceiveBtn then
		self.ReceiveBtn.Enabled = not state and num == limit
	end
	if self.ReceiveLab then
		self.ReceiveLab.text = receive
	end
end

function M:UpdateChapterReward(list)
	local len = #list
	for i=1,len do
		local data = list[i]
		if data then
			--local go = self:AddItem(self.CReward, self.CPrefab)
			local cell = ObjPool.Get(UIItemCell)
			cell:InitLoadPool(self.CReward.transform)
			cell:UpData(data.id, data.val)
			table.insert(self.CItems, cell)
		end
	end
	self.CReward:Reposition()
end
-------------------------------------------------------------------------
function M:UpdateMainMission()
	self:ClearMisson()
	local mission = MMgr.Main
	if not mission then return end
	local temp = mission.Temp
	local chapter = temp.chapter
	if temp.cEnd then chapter = temp.cEnd end
	self:UpdateChapterInit(chapter)
	self:UpdateMissionTitle(temp.name)
	self:UpdateMissionInteractive(mission:GetSubmitDes())
	self:UpdateMissionTarget(mission:GetTargetsDes("bfad77"))
	self:UpdateMReward(temp)
end

function M:UpdateChapterInit(chapter)
	if not self.ChapterList then return end
	for i,v in ipairs(self.ChapterList) do
		local id = v.Temp.id
		if id <= chapter then
			v.Toggle:IsEnabled(true, true, Color.New(242, 153, 0, 255) /255)
			v.BG.color = Color.New(1,1,1,0.5)
			if id == chapter then
				v.Toggle:Set(true, true)
				self:UpdateChapterData(v.Temp)
				v.Label.color = Color.New(165,61,33,255)/255
			else
				v.Label.color = Color.New(244,221,189,255)/255
			end
			local data = CMgr.ChapterDic[tostring(id)]
			if data and v.IsEnd then
				v.IsEnd:SetActive(data.IsReward)
			end
		end
		if v.Lock then
			v.Lock:SetActive(id > chapter)
		end
	end
end

function M:UpdateMissionTitle(title)
	if self.Title then
		self.Title.text = title
	end
end

function M:UpdateMissionInteractive(interactive)
	if self.Interactive then
		self.Interactive.text = interactive
	end
end

function M:UpdateMissionTarget(target)
	if self.Target then
		self.Target.text = target
	end
end

function M:UpdateMReward(temp)
	local exp = temp.exp
	local item = temp.item
	if exp and exp ~= 0 then
		--local go = self:AddItem(self.MReward, self.MPrefab)

		if temp.expType ~= 0 then
			exp = PropTool.GetExp(exp/ 10000)
		end
		local cell = ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.MReward.transform)
		cell:UpData(100, exp)
		table.insert(self.MItems, cell)
	end
	if item then
		local count = #item
		for i = 1, count do
			local data = item[i]
			if data then
				--local go = self:AddItem(self.MReward, self.MPrefab)
				local cell = ObjPool.Get(UIItemCell)
				cell:InitLoadPool(self.MReward.transform)
				cell:UpData(data.id, data.num)
				cell:UpBind(data.bind == 1)
				table.insert(self.MItems, cell)
			end
		end
	end
	self.MReward:Reposition()
end
-------------------------------------------------------------------------
function M:AddItem(grid, prefab)
	local go = GameObject.Instantiate(prefab)
	go:SetActive(true)
	t = go.transform
	t.parent = grid.transform
	t.localScale = Vector3.one
	t.localPosition = Vector3.zero
	return go
end
-------------------------------------------------------------------------

function M:ClickReceiveBtn(go)
	if not self.Data then 
		iTrace.eError("hs","未选择章节，不能领取")
		return 
	end
	CMgr:ReqChapterRewardTos(self.Data.id)
end

function M:ClickExecuteBtn(go)
	local mission = MMgr.Main
	if not mission then return end
	Hangup:SetSituFight(false);
	Hangup:SetAutoSkill(false);
	Hangup:SetAutoHangup(true);
	MMgr:Execute(false)
	self.CurExecuteType = mission.type
	MMgr:UpdateCurMission(self.Mission)
	mission:AutoExecuteAction(MExecute.ClickItem) 
	self:CloseClick()
end
-------------------------------------------------------------------------

function M:OpenCustom()
	self:AddEvent()
	self:UpdateMainMission()
end

function M:CloseCustom()
	self:RemoveEvent()
end

function M:ClearChapter()
	if self.Des then self.Des.text = "" end
	if self.Progress then self.Progress.text = "" end
	if self.Slider then self.Slider.value = 0 end
	self:ClearCItems(self.CReward, self.CItems)
end

function M:ClearMisson()
	if self.Title then self.Title.text = "" end
	if self.Interactive then self.Interactive.text = "" end
	self:ClearCItems(self.MReward, self.MItems)
end

function M:ClearCItems(grid, items)
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
		grid:GetChildList():Clear()
	end
end

function M:CloseClick()
	self:Close()
	JumpMgr.eOpenJump()
end

function M:Clear()
	self:ClearChapter()
	self:ClearMisson()
	self:UnloadPic()
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.PicName) then
		AssetMgr:Unload(self.PicName, ".jpg", false)
	end
	self.PicName = nil
end

function M:DisposeCustom()
	self:Clear()
end

return M

--endregion
