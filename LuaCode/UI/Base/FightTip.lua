--[[
主界面战力属性
--]]
require("Tween/TweenDigtal")
FightTip=UIBase:New{Name="FightTip"}
local My = FightTip
local data = User.instance.MapData
local Ass = Loong.Game.AssetMgr.LoadPrefab

function My:InitCustom()
	local trans = self.root
	local T = TransTool.FindChild
	local C = ComTool.Get

	self.TipAudioSource = trans:GetComponent("AudioSource")
	self.TipLabelRoot = T(trans, "Property")
	self.TipLabelPrefab = T(trans, "Label")
	self.TipFighting = T(trans, "Fighting")
	self.addFightLabel = C(UILabel, self.TipFighting.transform, "addFightLabel", self.Name, false)
	self.add=T(self.TipFighting.transform,"Panel/add")
	self.redu=T(self.TipFighting.transform,"Panel/redu")
	self.FightTween = self.TipFighting:GetComponent("UIPlayTween")

	self.fxB=T(trans,"FX_b")

	self.TipFightLabel = C(UILabel, self.TipFighting.transform, "FightLabel/FightLabel", self.Name, false)
	self.tweenDigtal = TweenDigtal:New()
	self.tweenDigtal.label = self.TipFightLabel
	self.tweenDigtal.last = data.AllFightValue

	self.eff=T(trans,"FX_power_up")
	self.CurLv = data.Level
	self.tweenDigtal.current=data.AllFightValue
	self:AddEvent()
	self.OpenList = {} --存放可以设置值的label
	self.CloseList = {} --存放等待设置移动效果的  TweenAlpha消失，label可以重新使用
	self.isBegain=false

	self.timer=ObjPool.Get(iTimer)
	self.timer.seconds=0.2
	self.timer.complete:Add(self.FireCb,self)
end

--是否能被记录
function My:CanRecords()
	do return false end
end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return true end
end

function My:OpenCustom()
	StopCoroutine(self.OnStartPlay)
	if self.OpenList then
		local T = self.TipLabelRoot.transform
		while T.childCount > 0 do
			local trans = T:GetChild(0)
			trans.parent = nil
			GameObject.Destroy(trans.gameObject)
		end
	end
	-- self.OpenList = {} --存放可以设置值的label
	-- self.CloseList = {} --存放等待设置移动效果的  TweenAlpha消失，label可以重新使用
end

function My:AddEvent()
	local EH = EventHandler
	self.OnStartPlay = function() self:StartPlay() end
	local M = EventMgr.Add
	M("OnUpdateBaseProperty", EH(self.UpdateBaseProperty, self))
	FightVal.eChgFv:Add(self.UpFightValue, self);
end

function My:RemoveEvent()
	local EH = EventHandler
	local M = EventMgr.Remove
	M("OnUpdateBaseProperty", EH(self.UpdateBaseProperty, self))
	FightVal.eChgFv:Remove(self.UpFightValue, self);
end

function My:Update()
	if self.tweenDigtal then
		self.tweenDigtal:Update()
	end
end

--更新战斗力包含装备穿戴（战力上升和下降） --策划说下降不提示了。。。
function My:UpFightValue()
	--Ass("FX_power_up", GbjHandler(self.LoadEff,self))
	local addValue = data.AllFightValue - self.tweenDigtal.current
	self.tweenDigtal.current = data.AllFightValue
	if addValue<=0 then return end
	self.addValue=addValue

	self.timer:Start()
	self.fxB:SetActive(false)
	self.fxB:SetActive(true)
end

function My:FireCb()
	if self.eff then
		self.eff:SetActive(false)
		self.eff:SetActive(true)
	end
	self.add:SetActive(true)
	self.redu:SetActive(false)
	self.count=1
	local global = GlobalTemp["115"]
	if not global then iTrace.eError("xiaoyu","Global表为空  id: 115")return end
	self.global=global
	local val = global.Value1 

	local id = val[self.count].id
	local va = val[self.count].value
	self.addFightLabel.text="+"..math.ceil(self.addValue*va/100/100)

	self.time=0
	self.isBegain=true	 

	--升级播放音效
	if self.TipAudioSource ~= nil then self.TipAudioSource:Play() end
	--self.Coroutine = coroutine.start(self.OntCortinue,self)
	if not StrTool.IsNullOrEmpty(self.TipFightLabel.text) then
		self.TipFighting.gameObject:SetActive(true)
		self.FightTween.resetOnPlay = true
		--self.FightTween:Play(true)
	else
		self.TipFighting.gameObject:SetActive(false)
	end
	if self.gbj.activeSelf then
		StartCoroutine(self.OnStartPlay)
	end
end

function My:Update()
	if self.isBegain==false then return end	
	self.time=self.time-Time.deltaTime
	if self.time<=0 then 		
		self.count=self.count+1
		local val = self.global.Value1 
		if self.count>#val then self.isBegain=false self.TipFighting.gameObject:SetActive(false) return end
		local id = val[self.count].id
		local va = val[self.count].value

		self.time=id
		self.addFightLabel.text="+"..math.ceil(self.addValue*va/100/100)
	end
	
end

function My:StartPlay()
	if #self.CloseList ~= 0 and self.gbj.activeSelf then
		local list = self.CloseList
		while(#list > 0)do
			local length = #list
			if list[length] == nil then
				return
			end
			local go = list[length].gameObject
			go:SetActive(true)
			local uiplayTween = go:GetComponent("UIPlayTween")
			uiplayTween.resetOnPlay = true
			uiplayTween:Play(true)
			table.remove(list, length)
			table.remove(self.CloseList, length)
			WaitForSeconds(0.4)
		end
	end
end

--更新基础属性增加值 为升级飘字做准备
function My:UpdateBaseProperty(key, value)
	if not self.OpenList then self.OpenList = {} end
	if #self.OpenList == 0 then self:CreatePropertyLabel() end
	local openLen = #self.OpenList
	local label = self.OpenList[openLen]
	local curTweenAlpha = label.gameObject:GetComponent("TweenAlpha")
	table.insert(self.CloseList, 1, curTweenAlpha)
	local func = function() table.insert(self.OpenList, 1, label) end
	EventDelegate.Set(curTweenAlpha.onFinished, EventDelegate.Callback(func))
	label.text = GetBasePropertyName(key).."+"..value
	table.remove(self.OpenList, openLen)
end


function My:CreatePropertyLabel()
	local go = GameObject.Instantiate(self.TipLabelPrefab)
	go.transform.parent = self.TipLabelRoot.transform
	go.transform.localPosition = Vector3.New(150, 0, 0)
	go.transform.localScale = Vector3.one
	go.name = tostring(My.index)
	My.index = My.index + 1
	table.insert(self.OpenList, 1, go:GetComponent("UILabel"))
end

-- function My:LoadEff(go)
-- 	go.transform.parent = self.root
-- 	go.transform.localPosition = Vector3.zero
-- 	go.transform.localScale = Vector3.one
-- 	go:SetActive(true)
-- end

function My:StartPlay()
	if #self.CloseList ~= 0 and self.gbj.activeSelf then
		local list = self.CloseList
		while(#list > 0)do
			local length = #list
			if list[length] == nil then
				return
			end
			local go = list[length].gameObject
			go:SetActive(true)
			local uiplayTween = go:GetComponent("UIPlayTween")
			uiplayTween.resetOnPlay = true
			uiplayTween:Play(true)
			table.remove(list, length)
			table.remove(self.CloseList, length)
			WaitForSeconds(0.4)
		end
	end
	StopCoroutine(self.OnStartPlay)
end

function My:Clear()
	self:Close()
end

function My:CloseCustom()
	if self.eff then self.eff:SetActive(false) end
end

function My:DisposeCustom()
	self:RemoveEvent()
	if self.tweenDigtal then
		self.tweenDigtal:Dispose()
	end
	while #self.OpenList>0 do
		local go=self.OpenList[#self.OpenList].gameObject
		GameObject.Destroy(go)
		self.OpenList[#self.OpenList]=nil
	end
	while #self.CloseList>0 do
		local go=self.CloseList[#self.CloseList].gameObject
		GameObject.Destroy(go)
		self.CloseList[#self.CloseList]=nil
	end
	if self.timer then 
		self.timer:AutoToPool()
		self.timer=nil 
	end
end

return My