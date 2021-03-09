--region UIOperationTip.lua
--Date
--此文件由[HS]创建生成

UIOperationTip = UIBase:New{Name ="UIOperationTip"}
local M = UIOperationTip

local OMgr = OpenMgr
M.eClose=Event();

function M:InitCustom()
	self.Persitent = true;
	local name = "可操作提示面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Icon = C(UITexture, trans, "Icon", name, false)
	--self.Tween = C(TweenScale,trans,"Icon",name,false)
	self.Label = C(UILabel, trans, "Label", name, false)
	self.Container = T(trans,"Container")
	self.SysTitle = T(trans, "System")
	self.SkillTilt = T(trans, "Skill")

	self.TimerTool = ObjPool.Get(DateTimer)
    self.TimerTool.complete:Add(self.EndTimer, self)
	self.TimerTool.seconds = 2.5
	self.IsCountDown = false
	self.IsFlyIcon = false
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.Container then
		E(self.Container, self.OnClickContainer, self, nil, false)
	end
end

function M:RemoveEvent()
end

function M:UpdateOperation()
	if not OMgr:IsCheckOpenList() then 
		self:Close()
		return
	end
	if self.IsCountDown then return end
	self.IsCountDown = true
	self:UpdateData()
end

function M:UpdateData()
	self:UnloadIcon()
	local list = OMgr.OperationList
	
	local data = list[1]
	if not data then return end
	table.remove(list, 1)
	local len = #list 
	local name = data.Name
	local icon = data.Icon
	self:UpdateTitlte(data.Type)
	self.Label.text = name

	if StrTool.IsNullOrEmpty(icon) then
		if len > 0 then
			self:UpdateData()
		else
			self:Close()
		end
		return
	end
	self.LoadName = icon
	local del = ObjPool.Get(DelLoadTex)
	del:Add(data)
	del:SetFunc(self.SetTex, self)
	AssetMgr:Load(icon,ObjHandler(del.Execute,del))
    self.TimerTool:Start()
end

function M:SetTex(tex,data)
	if not self.Icon then 
		Destroy(tex)
		self:UnloadIcon()
		return
	end
	self.Icon.mainTexture = tex
	--[[
	if self.Tween then
		self.Tween:ResetToBeginning()
		self.Tween:Play(true)
	end
	]]--
	
	if data.Temp and data.Temp.openType == 3 then return end
	local fly = data.flyType
	if not fly then return end
	local go = self.Icon.gameObject
	local copy = GameObject.Instantiate(self.Icon.gameObject)
	copy.transform.name = tostring(data.ID)
	local ts = copy:GetComponent("TweenScale")
	if ts then Destroy(ts) end
	copy.transform.localPosition = go.transform.position;
	copy.transform.localRotation = go.transform.rotation;
	copy.transform.localScale = go.transform.localScale;
	OMgr:ShowFlyEffect(data, copy)
	self.IsFlyIcon = true
end

function M:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.LoadName) then
		AssetMgr:Unload(self.LoadName, ".png", false)
	end
	self.LoadName = nil
end

function M:UpdateTitlte(type)
	local value = type == 1
	if self.SysTitle then self.SysTitle:SetActive(value) end
	if self.SkillTilt then self.SkillTilt:SetActive(not value) end
end

function M:EndTimer()
	if not OMgr:IsCheckOpenList() then 
		self:Close()
		return
	end
	self:UpdateData()
end

function M:OnClickContainer(gameObject)
	self:EndTimer()
end

function M:OpenCustom()
	Hangup:Pause(self.Name)
end

function M:CloseCustom()
	--if not LuaTool.IsNull(self.Effect) then self.Effect:SetActive(false) end
	Hangup:Resume(self.Name)
	MissionMgr:Execute(false)
	M.eClose();
    self:Clear()
end

function M:Clear()
	if self.Infos then 
		TableTool.ClearDic(self.Infos)
	end
	if self.TimerTool then self.TimerTool:Stop() end
	self.IsCountDown = false
	self:UnloadIcon()
	self.IsFlyIcon = false
end

function M:DisposeCustom()
	if self.TimerTool then
		self.TimerTool:AutoToPool()
	end
	self.TimerTool = nil
end

function M:CloseClean()
	return true
end


return UIOperationTip

--endregion
