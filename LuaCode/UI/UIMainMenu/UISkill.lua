
UISkill = {}
local M = UISkill

local OMgr = OpenMgr

function M:New(parent, go)
	self.Parent = parent
	self.GO = go
	local trans = go.transform;
	local name = "技能界面";
	local C = ComTool.Get
	local T = TransTool.FindChild

	--点击按钮
   	self.playTween=C(UIPlayTween,trans,"MoveRoot",name,false)
   	self.Tween = C(TweenPosition, trans, "MoveRoot", name, false)
	self.skillAttack = C(UIButton,trans,"MoveRoot/Liuhai/SkillAttack",name,false);

	self.anchor = C(UIWidget, trans, "MoveRoot/Liuhai", name, false)
	self.oriLeft = self.anchor.leftAnchor.absolute
	self.oriRight = self.anchor.rightAnchor.absolute

	local temp = GlobalTemp["7"]
	if temp ~= nil then
		self.SkillGlobal = temp.Value4
	end
	self.Btns1 = self:GetBtnData(trans, 1)
	self.Btns2 = self:GetBtnData(trans, 2)
	self.Btns3 = self:GetBtnData(trans, 3)
	self.Btns4 = self:GetBtnData(trans, 4)
	self.Btns5 = self:GetBtnData(trans, 5)
	


	self.TimerTool = ObjPool.Get(DateTimer)
    self.TimerTool.complete:Add(self.EndTimer, self)
	self.TimerTool.seconds = 1.2
	self.IsCountDown = false

	self.CurUnlockBtn = nil
	self.IsUnlockSkill = false
	local E = UITool.SetLsnrSelf

	E(self.Btns1.Btn, self.Skill_1OnClick, self)
	E(self.Btns2.Btn, self.Skill_2OnClick, self)
	E(self.Btns3.Btn, self.Skill_3OnClick, self)
	E(self.Btns4.Btn, self.Skill_4OnClick, self)
	E(self.Btns5.Btn, self.Skill_5OnClick, self)
	E(self.skillAttack, self.SkillAttackOnClick, self)

	self:AddEvent();
	EventMgr.Trigger("SkillInit",self.skillAttack.gameObject,self.Btns1.Btn.gameObject,self.Btns2.Btn.gameObject,self.Btns3.Btn.gameObject,self.Btns4.Btn.gameObject,self.Btns5.Btn.gameObject);
	return self
end

function M:GetBtnData(trans, index)
	local name = "技能按钮"
	local btnData = {}
	local C = ComTool.Get
	local T = TransTool.FindChild
	btnData.Btn = C(UIButton, trans, string.format("MoveRoot/Liuhai/Skill_%s", index), name, false);
	btnData.Icon = C(UISprite, trans,string.format("MoveRoot/Liuhai/Skill_%s/Icon", index), name,false);
	btnData.CD = C(UISprite, trans,string.format("MoveRoot/Liuhai/Skill_%s/CD", index), name,false);
	btnData.BG = T(trans,string.format("MoveRoot/Liuhai/Skill_%s/Background", index));
	btnData.PlayTween = btnData.Btn.gameObject:GetComponent("UIPlayTween")
	btnData.Open = C(UILabel, trans, string.format("MoveRoot/Liuhai/Skill_%s/Lock/OpenLevel", index), name, false)
	if btnData.Icon then btnData.Icon.spriteName = "" end
	self:SetOpenLv(btnData,index);
	return btnData
end

--设置开放等级
function M:SetOpenLv(btnData,index)
	if self.SkillGlobal and self.SkillGlobal[index] then
		local key = self.SkillGlobal[index].k;
		local str = self.SkillGlobal[index].s;
		if key == index then
			btnData.Open.text = string.format("%s", str);
		end
	end
end

--清除技能开启等级
function M:ClearOpenLv()
	self:ClrOpLvLbl(self.Btns1);
	self:ClrOpLvLbl(self.Btns2);
	self:ClrOpLvLbl(self.Btns3);
	self:ClrOpLvLbl(self.Btns4);
	self:ClrOpLvLbl(self.Btns5);
end

--清除技能开启等级文本
function M:ClrOpLvLbl(btnData)
	if btnData ~= nil then
		btnData.Open.text = "";
	end
end

function M:AddEvent()
	self:SetEvent("Add")
	self:UpdateEvent(EventMgr.Add)
end

function M:UpdateEvent(M)
	local EH = EventHandler
	M("UnlockSkill", EH(self.UnlockSkill,self))
end

function M:SetEvent(fn)
	OMgr.eShowSkillEff[fn](OMgr.eShowSkillEff, self.ShowSkillEff, self)
end

function M:RemoveEvent()
	self:SetEvent("Remove")
	self:UpdateEvent(EventMgr.Remove)
end

--屏幕发生旋转
function M:ScrChg(orient, init)
	local reset = UITool.IsResetOrient(orient)
	UITool.SetLiuHaiAbsolute(self.anchor, false, not reset, self.oriLeft,self.oriRight,-1)
end

--播放技能开启特效
function M:ShowSkillEff(data, go)	
	if not data then return end
	self.OpenData = data
	Hangup:Pause(OpenMgr.FlyIconPause)
	if LuaTool.IsNull(go) == true then return end
	go.transform.parent = self.Tween.transform
	go.transform.localScale = Vector3.one
	local fly = ComTool.Add(go, UIFly)
	if fly then
		local pos = go.transform.localPosition
		local tarPos = self:GetTarPos(data)
		if not tarPos then return end
		fly.anchors1 = Vector3.New(pos.x + 100, pos.y - 100,0)
		fly.anchors2 = Vector3.New(pos.x + 200 ,pos.y - 200,0)
		fly.targetPos = tarPos
		fly.time = 0.7
		fly.endDelay = 0
	end
	local scale = ComTool.Add(go, TweenScale)
	if scale then
		scale.from = go.transform.localScale
		scale.duration = 0.7
	end

	go:SetActive(true)
	if self.Parent and self.Parent.active ~=1 then return end
	if self.IsCountDown == true then return end
	self.IsCountDown = true
	self.TimerTool:Start()
end

--倒计时结束
function M:EndTimer()
	self.IsCountDown = false
	local data = self.OpenData
	if not data then return end
	self:UnlockSkill(data)
	if Hangup:IsPause() == true then
		Hangup:Resume(OpenMgr.FlyIconPause)
		MissionMgr:Execute(false)
		Hangup:ClearAutoInfo()
		Hangup:SetAutoHangup(true)
	end
end

--获取目标坐标
function M:GetTarPos(data)
	local trans = nil
	if data.Other == 1 then 
		trans = self.Btns1.Btn.gameObject.transform
	elseif data.Other == 2 then 
		trans = self.Btns2.Btn.gameObject.transform
	elseif data.Other == 3 then 
		trans = self.Btns3.Btn.gameObject.transform
	elseif data.Other == 4 then 
		trans = self.Btns4.Btn.gameObject.transform
	elseif data.Other == 5 then 
		trans = self.Btns5.Btn.gameObject.transform
	end
	if not trans then
		iTrace.eError("hs", string.format( "技能开启没有找到对应的技能按钮 id:%s 位置:%s", data.Name, data.Other))
		return nil
	end
	return trans.localPosition
end

--解锁技能
function M:UnlockSkill(data)
	if not data then return end
	self.IsUnlockSkill = true
	if data.Other == 1 then 
		self:UnlockSkillToBtn(self.Btns1, data)
	elseif data.Other == 2 then 
		self:UnlockSkillToBtn(self.Btns2, data)
	elseif data.Other == 3 then 
		self:UnlockSkillToBtn(self.Btns3, data)
	elseif data.Other == 4 then 
		self:UnlockSkillToBtn(self.Btns4, data)
	elseif data.Other == 5 then 
		self:UnlockSkillToBtn(self.Btns5, data)
	end
	self.OpenData = nil
end

--加载解锁特效
function M:UnlockSkillToBtn(btnData, data)
	local name = btnData.Icon.spriteName
	if StrTool.IsNullOrEmpty(name) then return end
	self.CurUnlockBtn = btnData.Btn
	Loong.Game.AssetMgr.LoadPrefab("UI_Skill_Clik1", GbjHandler(self.UnlockSkillEffect,self))
	self:UpdateIcon(btnData,data.Icon)

end

--设置解锁特效
function M:UnlockSkillEffect(go)
	if not self.CurUnlockBtn then return end
	go.transform.parent = self.CurUnlockBtn.gameObject.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
end

function M:UpdateIcon( btnData, iconPath )
	if btnData == nil then
		return;
	end
	local pt = btnData.PlayTween
	local icon = btnData.Icon
	local path =  string.gsub(iconPath,".png","")
	if StrTool.IsNullOrEmpty(path) then return end
	if pt then 
		pt:Play(true)
	end
	btnData.BG:SetActive(true)
	if icon then
		icon.spriteName = path
	end
end

function M:UpdateSkillViewStatus(value)
	local delay = 0
	local playTween = self.playTween
	local tweenPos = self.Tween
	if value == false then
		delay = 0.2
	end
	if tweenPos then 
		tweenPos.delay = delay
	end
	if playTween then
		playTween:Play(value)
	end
end

function M:Open()
	self:NotOpen()
	if self.OpenData then
		if self.IsCountDown == true then return end
		self.IsCountDown = true
		self.TimerTool:Start()
	end
end

function M:Close()
	if self.TimerTool then 
		self.TimerTool:Stop() 
	end
	self:EndTimer()
end

function M:Dispose()
	self:RemoveEvent()
end

function M:NotOpen()
	local value = SceneMgr:IsOpenUISkill()
	
	self:SetActive(not value)
end

function M:SetActive(value)
	if self.GO then
		self.GO:SetActive(value)
	end
end

function M:Reset(btn,index)
	if btn then
		if btn.Icon then
			btn.Icon.spriteName = ""
		end
		if btn.Open then
			btn.Open.gameObject:SetActive(true)
		end
		if btn.CD then
			btn.CD.fillAmountValue = 0
		end
		if btn.BG then
			btn.BG:SetActive(false)
		end
		if btn.PlayTween then
			btn.PlayTween:Play(false)
		end
		self:SetOpenLv(btn,index);
	end
end

function M:Clear()
	self:Reset(self.Btns1,1)
	self:Reset(self.Btns2,2)
	self:Reset(self.Btns3,3)
	self:Reset(self.Btns4,4)
	self:Reset(self.Btns5,5)
	self.CurUnlockBtn = nil
	self.IsUnlockSkill = false
	if self.TimerTool then self.TimerTool:Stop() end
end

--设置技能图标
function M:SetSkillIcon(iconName1,iconName2,iconName3,iconName4,iconName5)
	if not StrTool.IsNullOrEmpty(iconName1) then
		self:UpdateIcon(self.Btns1, iconName1)
	else
		self:Reset(self.Btns1);
	end
	if not StrTool.IsNullOrEmpty(iconName2) then 
		self:UpdateIcon(self.Btns2, iconName2);
	else
		self:Reset(self.Btns2);
	end
	if not StrTool.IsNullOrEmpty(iconName3) then 
		self:UpdateIcon(self.Btns3, iconName3);
	else
		self:Reset(self.Btns3);
	end
	if not StrTool.IsNullOrEmpty(iconName4) then 
		self:UpdateIcon(self.Btns4, iconName4);
	else
		self:Reset(self.Btns4);
	end
	if not StrTool.IsNullOrEmpty(iconName5) then 
		self:UpdateIcon(self.Btns5, iconName5);
	else
		self:Reset(self.Btns5);
	end
end

--释放技能1
function M:Skill_1OnClick(go)
	EventMgr.Trigger("Skill_1OnClick",go)
end

--释放技能2
function M:Skill_2OnClick(go)
	EventMgr.Trigger("Skill_2OnClick",go)
end

--释放技能3
function M:Skill_3OnClick(go)
	EventMgr.Trigger("Skill_3OnClick",go)
end

--释放技能4
function M:Skill_4OnClick(go)
	EventMgr.Trigger("Skill_4OnClick",go)
end

--释放技能5
function M:Skill_5OnClick(go)
	EventMgr.Trigger("Skill_5OnClick",go)
end

--释放普通技能
function M:SkillAttackOnClick(go)
	EventMgr.Trigger("SkillAttackOnClick",go)
end

return M