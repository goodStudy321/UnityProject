--[[
创角界面
--]]
UICreate=Super:New{Name="UICreate"}
local M =UICreate
local lsMgr = LoginSceneMgr

function M:Init(go)
    self.trans=go.transform
    local C = ComTool.Get
    local T = TransTool.FindChild

	local camera=GameObject.Find("Camera_Character")
	self.camera=camera:GetComponent(typeof(Camera))
	self.Select = T(self.trans, "Select")
	UITool.SetLiuHaiAnchor(self.trans,"Select",self.Name,true)

	self.STween = T(self.trans,"Select/Tween")
   	self.SelectPT = self.STween:GetComponent("UIPlayTween")

	self.Enter = T(self.trans, "Enter")
	self.ETween = T(self.trans, "Enter/Tween")
   	self.EnterPT = self.ETween:GetComponent("UIPlayTween")
	self.NameLabel = C(UIInput, self.trans, "Enter/nameInput", name, false)

	local E = UITool.SetBtnClick
	self.MaleBtn=C(UIToggle,self.trans,"Select/Tween/MaleBtn",self.Name,false)
	self.FemaleBtn=C(UIToggle,self.trans,"Select/Tween/FemaleBtn",self.Name,false)
    E(self.trans,"Select/Tween/MaleBtn", self.Name,self.OnMale, self)
    E(self.trans,"Select/Tween/FemaleBtn", self.Name,self.OnFemale, self)
    E(self.trans,"Enter/RandomBtn", self.Name,self.OnRandom, self)
	E(self.trans, "Enter/EnterBtn",self.Name,self.OnCreate, self)

	self:AddEvent()
   	self:InitData()
end

function M:InitData()
	self.FirstLen = #CfgNames.First
	self.FemaleLen = #CfgNames.Female
	self.MaleLen = #CfgNames.Male
	--self.SpecialLen = #CfgNames.Special
	math.randomseed(os.time())
end

function M:AddEvent()   
    local M = EventMgr.Add
    local EH = EventHandler
	M("OnMoveUISelectPlayer", EH(self.PlayTween, self))
	--M("OnLoginSuccessful", EH(self.OnLoginSuc, self))
	--AccMgr.eLogoutSuc:Add(self.OnLogoutSuc, self)
end

function M:RemoveEvent()
    local M = EventMgr.Remove
    local EH = EventHandler
	M("OnMoveUISelectPlayer", EH(self.PlayTween, self))
	--M("OnLoginSuccessful", EH(self.OnLoginSuc, self))
	--AccMgr.eLogoutSuc:Remove(self.OnLogoutSuc, self)
end

function M:UpdateName()
	local first = self:RandomName(CfgNames.First, self.FirstLen)
	local cfg = nil
	if self.Sex==1 then
		cfg=self:RandomName(CfgNames.Male, self.MaleLen)
	elseif self.Sex==0 then
		cfg=self:RandomName(CfgNames.Female, self.FemaleLen)
	end
	local special = ""
	--if math.random()<=0.25 then special=self:RandomName(CfgNames.Special, self.SpecialLen) end
	local name = string.format("%s%s", first, cfg)
	self:UpValue(name)
end	

function M:UpValue(name)
	if self.NameLabel then 
		self.NameLabel.value = name
	end
end

function M:RandomName(list, len)
	local childList = list
	local index  = math.random(len)
	local str = childList[index]
	return str
end

--是否有输入符号，数字
function M:IsCheck(str)
	local ishas = false
	local pos=nil
	
	pos=string.find(str,"%w" )
	if pos then ishas=true end

	pos=string.find(str," " )
	if pos then ishas=true end

	return ishas
end

--是屏蔽字
function M:IsSensitiveStr(str)
	local content,isMask = MaskWord.SMaskWord(str)
	if isMask then 
		return true
	end
	return false
end

function M:PlayTween(value)
	if self.SelectPT then
		self.SelectPT:Play(value)
	end
	if self.EnterPT then
		self.EnterPT:Play(value)
	end
end

--点击男性角色按钮
function M:OnMale(go)
	LoginSceneMgr:HideAllCharNode();

	CutscenePlayMgr.instance:SkipCutscene();
	CutscenePlayMgr.instance:PlayCutscene("Character_Create_male", self.camera, false, false, false)
	self.Sex = 1
	self.Career = 2
	lsMgr:SelectPlayer(self.Sex)
	--Audio.Instance:Play("Male.mp3");
	self:UpdateName()
end

--点击女性角色按钮
function M:OnFemale(go)
	LoginSceneMgr:HideAllCharNode();

	CutscenePlayMgr.instance:SkipCutscene();
	CutscenePlayMgr.instance:PlayCutscene("Character_Create_female",self.camera, false, false, false)	
	self.Sex = 0
	self.Career = 1
	lsMgr:SelectPlayer(self.Sex)
	--Audio.Instance:Play("Female.mp3");
	self:UpdateName()
end

--点击随机
function M:OnRandom(go)
	self:UpdateName()
end

--点击创建角色
function M:OnCreate()
	local name = nil
	if self.NameLabel then name = self.NameLabel.value end
	if StrTool.IsNullOrEmpty(name) then
		UITip.Error("请输入角色名字！！！")
		return
	end

	if self:IsCheck(name)==true then
		UITip.Error("角色名包含字母、数字或符号，请重新输入！！！")
		return 
	end
	if self:IsSensitiveStr(name) == true then
		UITip.Error("角色名包含非法字符，请重新输入！！！")
		iTrace.eLog("HS",string.format("角色名{%s}包含非法字符，请重新输入！！！", name))
		self.NameLabel.value = ""
		return
	end
	Mgr.ReqCreate(name, self.Sex, self.Career)
end

function M:OpenUICallback(name)
	
end

-- function M:OnLoginSuc()
--     --SceneMgr:ReqPreEnter(User.SceneId, true)
--     self:Close()
-- end

-- function M:OnLogoutSuc()
-- 	--Mgr.DisConnect()
-- 	lsMgr:ShowLogin()
-- 	self:Close()
-- end


function M:Open()
	if lsMgr ~= nil then
		lsMgr:AddEvent();
	end

	self.trans.gameObject:SetActive(true)

	self:RandomSex()
end

--随机创角性别
function M:RandomSex()
	local f = math.ceil(math.random()*2)
	local femalepos=f<=1 and 259 or 98
	local malePos =f<=1 and 98 or 259
	self.MaleBtn.transform.localPosition=Vector3.New(126,malePos,0)
	self.FemaleBtn.transform.localPosition=Vector3.New(126,femalepos,0)

	if f<=1 then 
		self.FemaleBtn.value=true
		self:OnFemale()		
	else
		self.MaleBtn.value=true
		self:OnMale()	
	end
end

function M:Close()
	CutscenePlayMgr.instance:SkipCutscene();
	if lsMgr ~= nil then
		lsMgr:HideAllCharNode();
		lsMgr:RemoveEvent();
	end

	self.NameLabel.value = ""
	self.trans.gameObject:SetActive(false)
end

function M:Dispose()
    self:RemoveEvent()
	if lsMgr then lsMgr:Dispose() end
	TableTool.ClearUserData(self)
end