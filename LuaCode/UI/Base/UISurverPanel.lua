--[[
	AU:Loong
	TM:2017.05.11
	BG:描述
--]]

UISurverPanel = UIBase:New{Name = "UISurverPanel"}
local M = UISurverPanel

function M:InitCustom()
	local name = self.Name
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local str = "Select/Scroll View/Grid"

	self.StartRoot = T(trans, "Start")
	self.StartGrid = T(trans, "Start/Grid")
	self.SelectRoot = T(trans, "Select")
	self.CloseBtn = T(trans, "Close")
	self.EndRoot = T(trans, "End")
	self.Btn = T(trans, "Button")
	self.Down = T(trans, "Sprite/Down")
	self.BtnLab = C(UILabel, trans, "Button/Label", name, false)
	self.Question = C(UILabel, trans, "Select/Question", name, false)
	self.Grid = C(UIGrid, trans, str, name, false)
	self.Prefab = T(trans, str.."/Item", name, false)
	self.Tex = C(UIInput, trans, "Select/Tex", name, false)
	self.ShowTex = C(UITexture, trans, "TexPanel/ShowTex", name, false)
	self.ShowTween = C(UITweener, trans, "TexPanel/ShowTex", name, false)
	self.mask = T(trans, "TexPanel/mask")
	self.sView = C(UIScrollView, trans, "Select/Scroll View")

	self.time = 3600
	self.IsAnswer = false
	self.IsComplete = false
	self.IsSelect = true
	self.AnswerList = {}

	self.SelectList = {}
	self.TextList = {}
	self.TexList = {}
	self.textureList = {}
	self.pathList = {}
	self.TexIndex = 0

	self.jumpIndex = nil
	self.jumpIndexDic = {}
	self.jumpedDic = {}
	self.cellList = {}
	self.result = {}
	
	self:AddEvent()
	self:InitAwards()
	self:CreateTimer(self.time)
	SurverMgr:UpAction(false)
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Btn then	
		E(self.Btn, self.OnClickBtn, self)
	end
	if self.CloseBtn then	
		E(self.CloseBtn, self.OnClickCloseBtn, self)
	end
	if self.mask then
		E(self.mask, self.OnMaskClick, self, nil, false)
	end
end


function M:RemoveEvent()
	-- body
end

function M:InitData()
	-- self.IsAnswer = false
	-- self.IsComplete = false
	-- self.IsSelect = true
	-- self.AnswerList = {}
	-- self.SelectList = {}
	-- self.TextList = {}
	local info = SurverMgr.SurverInfo
	if info == nil then self:Close() return end
	self.Info = info
	local len = #info
	if not len or len == 0 then self:Close() return end
	self.Len = len
	self.Index = 0
end

function M:UpdateAnswer()
	local jumpIndex = self.jumpIndex
	local info = self.Info
	local data = nil
	if jumpIndex then
		local key = tostring(jumpIndex)
		self.jumpedDic[key] = true
		self.Index = SurverMgr:GetIdByIndex(jumpIndex)
		if self.Index == nil then return end
		data = info[self.Index]
	else
		local isEnd = true
		for i=1, self.Len do--过滤题目跳跃
			if info[i] then--保护判断
				local id = info[i].id
				local sort = info[i].sort
				if tonumber(sort) > self.Index then
					local key = tostring(id)
					if not self.jumpedDic[key] then
						isEnd = false
						self.Index = i
						self.jumpedDic[key] = true
						break
					end
				end
			end
		end
		if isEnd then
			self:AddInfo()
			self:EndAnswer()
			return
		end
		data = info[self.Index]
	end

	-- iTrace.Error("index = "..self.Index.." answerLen = "..TableTool.GetDicCount(data.answer))
	-- iTrace.Error("quesId = "..data.quesId.." id = "..data.id.." question = "..data.question.." type = "..data.type.." max = "..data.max.." sort = "..data.sort)
	-- for k,v in pairs(data.answer) do
	-- 	iTrace.Error("key = "..v.key.." name = "..v.name.." img = "..v.img.." write = "..v.write.." nextId = "..v.nextId)
	-- end
	
	if data then
		self:UpdateQA(data)
		self.jumpIndex = nil
	else
		self:Close()
	end
end

function M:UpdateQA(data)
	self.data = data
	local question = data.question
	local tp = tonumber(data.type)
	local max = tonumber(data.max)
	local answer = data.answer
	self.Type = tp 
	self.Max = max
	local value = TableTool.GetDicCount(data.answer) > 0
	if question then
		self:UpdateQuestion(question, tp)
	end
	if value then
		self:UpdateAnswerSelect(answer, tp)
	end
	if self.Grid then
		self.Grid.gameObject:SetActive(value)
	end
	if self.Tex then
		self.Tex.gameObject:SetActive(not value)
	end
	self.IsSelect = value
end

function M:UpdateQuestion(value, tp)
	if self.Question then
		local tt = ""
		-- if tp == 2 then
		-- 	tt = "（多选）"
		-- end
		self.Question.text = value..tt
	end
end

function M:UpdateAnswerSelect(dic, tp)
	local len = TableTool.GetDicCount(dic)
	TableTool.ClearDic(self.jumpIndexDic)
	local isImage = self:IsImage(dic)
	local h = (isImage) and 280 or 56
	local l = (isImage) and 4 or 1
	self:SetGrid(h, l)
	local isDown = (len>5 and not isImage) and true or false
	self.Down:SetActive(isDown)
	local isLoad = false
	local tLen = #self.AnswerList
	if tLen < len then
		local start = tLen + 1
		for i=start,len do
			self:AddAnswer(i)
		end
		-- self.Grid:Reposition()
	elseif tLen > len then
		local start = len + 1
		for i=start,tLen do
			local index = start + (tLen-i)
			local t = self.AnswerList[index]
			if t and t.Root then
				t.Root.gameObject:SetActive(false)
				t.Toggle.value = false
				table.remove(self.AnswerList, index)
			end
		end
	end
	for i=1,len do
		local key = SurverMgr.strList[i]
		local v = dic[key]
		local info = self.AnswerList[i]
		local root = info.Root
		local toggle = info.Toggle
		local input = info.Input
		local image = info.Image
		info.type = tp
		if root then 
			root.gameObject:SetActive(true) 
		end
		if image then
			image.gameObject:SetActive(isImage)
			self:UpItemName(image, i)
			self:SetTog(tp, image, 56)
			if isImage then
				local tran = image.transform
				local C = ComTool.Get
				local TF = TransTool.Find
				local lab = C(UILabel, tran, "lab", "Surver", false)
				local tex = C(UITexture, tran, "Scroll View/tex", "Surver", false)
				local nullTex = C(UITexture, tran, "nullTex", "Surver", false)
				local big = TF(tran, "Scroll View/tex/big", "Surver")
				UITool.SetLsnrSelf(big, self.OnTween, self, nil, false)
				self:SetTexGo(tex, nullTex, false)
					lab.text = v.name
					self:SetTexGo(tex, nullTex, true)
					table.insert(self.TexList, tex)
					table.insert(self.pathList, v.img)
					if not isLoad then
						WWWTool.LoadTex(self.pathList[1], self.SetTex, self)
						isLoad = true
					end
					if StrTool.IsNullOrEmpty(v.nextId) == false then
						self:SetJumpIndexDic(i, v.nextId)
					end
			end
		end
		if toggle then
			local isShow = v.write ~= 1
			toggle.gameObject:SetActive(isShow and not isImage)
			self:UpItemName(toggle, i)
			self:SetTog(tp, toggle, 7)
			toggle.lab = v.name
			if StrTool.IsNullOrEmpty(v.nextId) == false then
				self:SetJumpIndexDic(i, v.nextId)
			end
		end
		if input then
			local isShow = v.write == 1
			input.gameObject:SetActive(isShow and not isImage)
			self:UpItemName(input, "Input")
			if isShow then
				local label = ComTool.Get(UILabel, input.transform, "Background/Label", "Surver", false)
				if label then label.text = "其他" end
				input.value = ""
				-- root:SetAsLastSibling()
			end
		end
	end
	self.Grid:Reposition()
end

--更新选项名字
function M:UpItemName(item, name)
	if item.gameObject.activeSelf then
		item.transform.parent.name = name
	end
end

--设置跳转索引字典
function M:SetJumpIndexDic(id, val)
	local key = tostring(id)
	self.jumpIndexDic[key] = tonumber(val)
end

--点击播放动画
function M:OnTween(go)
	local target = go.transform.parent
	local tex = ComTool.GetSelf(UITexture, target, "Surver")
	self.ShowTex.mainTexture = tex.mainTexture
	self:SetTexSize(self.ShowTex, 700)
	self.ShowTween:PlayForward()
	self.mask:SetActive(true)
end

--点击遮罩
function M:OnMaskClick(go)
	self.ShowTween:PlayReverse()
	self.mask:SetActive(false)
end

--设置贴图
function M:SetTex(tex, err)
	if err then
		-- iTrace.Error("SJ", "图片加载失败")
		return
	else
		self.TexIndex = self.TexIndex + 1
		local index = self.TexIndex
		if self.TexList[index] == nil then return end
		local texture = self.TexList[index]
		texture.mainTexture = tex
		self:SetTexSize(texture, 380)
		if self.pathList[index+1] == nil then return end
		WWWTool.LoadTex(self.pathList[index+1], self.SetTex, self)
	end
	table.insert(self.textureList, tex)
end

--设置贴图尺寸大小
function M:SetTexSize(tex, size)
	tex:MakePixelPerfect()
	local ratio = tex.width / tex.height
	tex.width = size
	tex.height = tex.width / ratio
end

--设置贴图的状态
function M:SetTexGo(tex, nullTex, state)
	tex.gameObject:SetActive(state)
	nullTex.gameObject:SetActive(not state)
end

--清空贴图列表
function M:ClearTexList()
	self.TexIndex = 0
	self.TexList = {}
	self.pathList = {}
end

--设置Grid参数
function M:SetGrid(height, limit)
	self.Grid.cellHeight = height
	self.Grid.maxPerLine = limit
end

--判断是否是图片
function M:IsImage(dic)
	for k,v in pairs(dic) do
		if StrTool.IsNullOrEmpty(v.img) == false then
			return true
		end
	end
	return false
end

--设置Toggle
function M:SetTog(tp, tog, num)
	tog:Set(false)
	if tp == 0 then 
		tog.group = num
	elseif tp == 2 then 
		tog.group = 0
	end
end

function M:UpdateBtnLab(value)
	if self.BtnLab then
		self.BtnLab.text = value
	end
end

function M:AddAnswer(index)
	local grid = self.Grid
	local prefab = self.Prefab
	local go = GameObject.Instantiate(prefab)
	-- go.name = tostring(index)
	go:SetActive(true)
	local t = go.transform
	t.parent = grid.transform
	t.localScale = prefab.transform.localScale
	t.localPosition = Vector3.zero
	--local t = t:GetComponent("UIToggle")
	local info = {}
	info.Root = t
	info.Toggle = ComTool.Get(UIToggle, t, "Toggle", "Surver", false)
	info.Input = ComTool.Get(UIInput, t, "Input", "Surver", false)
	info.Image = ComTool.Get(UIToggle, t, "Image", "Surver", false)
	local M = UITool.SetLsnrSelf
	M(info.Toggle, self.ClickToggle, self)
	M(info.Input, self.ClickInput, self)
	M(info.Image, self.ClickImage, self)
	table.insert(self.AnswerList, info)
end

function M:ClickToggle(go)
	if self.Type ~= 0 then return end
	local toggle = UIToggle.current
	for i,v in ipairs(self.AnswerList) do
		v.Input.value = ""
	end
end

function M:ClickInput(go)
	if self.Type ~= 0 then return end
	for i,v in ipairs(self.AnswerList) do
		if v.Toggle.value == true then
			v.Toggle:Set(false)
		end
	end
end

function M:ClickImage(go)

end

function M:CheckAnswer()
	if self.IsComplete then return true end

	local len = #self.AnswerList
	local maxIndex = 0
	for i=1,len do
		local info = self.AnswerList[i]
		if info then
			local state1 = info.Toggle.value == true or not StrTool.IsNullOrEmpty(info.Input.value)
			local state2 = info.Image.value == true
			local state3 = info.Toggle.transform.parent.gameObject.activeSelf
			local state4 = info.Image.transform.parent.gameObject.activeSelf
			local state5 = info.Input.gameObject.activeSelf
			if (state1 and state3) or (state2 and state4) then
				if self.Type == 2 then
					if info.Toggle.value and state3 or info.Image.value and state4 then
						maxIndex = maxIndex + 1
					elseif not StrTool.IsNullOrEmpty(info.Input.value) and state5 then
						return true
					end
				else
					return true
				end
			end
		end
	end

	if self.Type == 2 then
		local state = false
		for i,v in ipairs(self.AnswerList) do
			local isInput = v.Input.gameObject.activeSelf
			if isInput and not StrTool.IsNullOrEmpty(v.Input.value) then
				state = true
			end
		end
		if state then
			return true
		else
			if self.Max == 0 and maxIndex > 0 then return true end
			if maxIndex > self.Max then
				UITip.Error("最多选择"..self.Max.."个选项！")
				return false
			elseif maxIndex == 0 then
				UITip.Error("请回答问题！")
				return false
			else
				return true
			end
		end
	elseif self.Type == 1 then
		return true
	end

	UITip.Error("请回答问题！")
	return false
end

function M:CheckIdea()
	if self.Tex and self.Tex.gameObject.activeSelf == true then
		if StrTool.IsNullOrEmpty(self.Tex.value) then
			UITip.Error("请填写您宝贵的建议！")
			return true
		end
	end
	return false
end

function M:OnClickBtn(go)
	self:ClearTexList()
	self.Down:SetActive(false)
	if self.IsComplete == true then
		if self:CheckAnswer() == false then 
			return 
		end 
		local useTime = self:StopTimer()
		local j = json.encode(self.result)
		SurverMgr:ReqSurverSummit(j, useTime)
		self:OnClickCloseBtn(nil)

		-- for k,v in pairs(self.result) do
		-- 	iTrace.Error("k = "..k)
		-- 	for k1,v1 in pairs(v) do
		-- 		iTrace.Error("k1 = "..k1.." v1 = "..v1)
		-- 	end
		-- end
	else
		if self.IsAnswer == false then
			self:StarAnswer(true)
		else
			if self:CheckAnswer() == false then return end 
			if self:CheckIdea() then return end

			local len = TableTool.GetDicCount(self.jumpIndexDic)
			local isLast = self.Index and (self.Len <= self.Index) and (len < 1)
			local isEnd = self:IsEndAnswer()
			-- iTrace.Error("isLast = "..tostring(isLast).." isEnd = "..tostring(isEnd))
			if isLast or isEnd then
				self:AddInfo()
				self:EndAnswer()
				return
			end
			self:AddInfo()
			if self.Tex then
				self.Tex.value = ""
			end
		end
		self:UpdateAnswer()
		self.Grid:Reposition()
		self.sView:ResetPosition()
	end
	self:ClearTex()
end

--是否结束答题
function M:IsEndAnswer()
	if self.jumpIndexDic == nil then return end
	for k,v in pairs(self.jumpIndexDic) do
		if v == 0 then
			return true
		end
	end
	return false
end

--添加答案数据
function M:AddData(tbl)
	local key = tostring(self.data.quesId)
	self.result[key] = tbl
end

function M:AddInfo()
	if self.Tex and self.Tex.gameObject.activeSelf == true then
		local str = self.Tex.value
		if not StrTool.IsNullOrEmpty(str) then
			local tbl = {}
			tbl.Z = str
			self:AddData(tbl)
		end
	else
		local list = self.AnswerList
		if list then
			local tbl = {}
			local len = #list
			for i=1, len do
				local info = self.AnswerList[i]
				local key = tostring(i)
				if info.Toggle and info.Toggle.value == true then
					self.jumpIndex = self.jumpIndexDic[key]
					local k = SurverMgr.strList[i]
					tbl[k] = ""
				elseif info.Input and not StrTool.IsNullOrEmpty(info.Input.value) then
					self.jumpIndex = self.jumpIndexDic[key]
					local k = SurverMgr.strList[i]
					tbl[k] = info.Input.value
					info.Input.value = ""
				elseif info.Image and info.Image.value == true then
					self.jumpIndex = self.jumpIndexDic[key]
					local k = SurverMgr.strList[i]
					tbl[k] = ""
				end
				self:AddData(tbl)
			end 
		end
	end
end

function M:OnClickCloseBtn(go)
	self:ClearTex()
	self:Close()
end

function M:OpenCustom()
	self:StarAnswer(false)
	self:InitData()
end

function M:CloseCustom()
end

function M:StarAnswer(value)
	self.IsAnswer = value
	local lab = ""
	if value == true then
		lab = "下一题"
	else
		lab = "开始答题"
	end
	self:UpdateBtnLab(lab)
	if self.StartRoot then
		self.StartRoot:SetActive(not value)
	end
	if self.SelectRoot then
		self.SelectRoot:SetActive(value)
	end
	if self.EndRoot then
		self.EndRoot:SetActive(false)
	end
end

function M:EndAnswer()
	self.IsComplete = true
	self:UpdateBtnLab("提交问卷")
	if self.StartRoot then
		self.StartRoot:SetActive(false)
	end
	if self.SelectRoot then
		self.SelectRoot:SetActive(false)
	end
	if self.EndRoot then
		self.EndRoot:SetActive(true)
	end
end

--初始化奖励
function M:InitAwards()
	for i,v in ipairs(SurverMgr.awardList) do
		local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.StartGrid.transform)
        cell:UpData(v.id, v.val)
        table.insert(self.cellList, cell)
	end
end

--创建计时器
function M:CreateTimer(rTime)
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
    timer.seconds = rTime
    timer:Start()
end

--停止计时器
function M:StopTimer()
	if not self.timer then return end
	local rTime = math.floor(self.timer:GetRestTime())
	local useTime = self.time - rTime
	self.timer:Stop()
	return useTime
end

--间隔倒计时
function M:InvCountDown()
    
end

--结束倒计时
function M:EndCountDown()
	UITip.Log("用时过长，请重新填写")
	self:Close()
end

--清理贴图
function M:ClearTex()
	for i,v in ipairs(self.textureList) do
		Destroy(v)
	end
	self.textureList = {}
end

function M:Clear()
	self:InitData()
	TableTool.ClearListToPool(self.cellList)
end

function M:DisposeCustom()
	self:RemoveEvent()
	self.StartRoot = nil
	self.Btn = nil
	self.SelectRoot = nil
	if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
	end
end

return M
