UICopyInfoBase = UIBase:New{Name ="UICopyInfoBase"}
local M = UICopyInfoBase

function M:InitCustom()
    self.left = TransTool.Find(self.root, "Left")
    self:ScreenChange(ScreenMgr.orient, true)
    self:InitSelf()
    self:UpdateCopyInfo()
    self:SetLsnr("Add")
	self:SetLsnrSelf("Add")
	self:SetEvent(EventMgr.Add)
end

function M:UpdateCur()
end

function M:UpdateSub()
end

function M:InitData()
end

function M:InitSelf()
end

function M:SetLsnrSelf(key)
end

function M:DisposeSelf()
end

function M:SetMenuStatus(value)
end

function M:SetLsnr(fn)
	local mgr = CopyMgr
	mgr.eUpdateCopyInfo[fn](mgr.eUpdateCopyInfo, self.UpdateCopyInfo, self)
	mgr.eUpdateCopyCur[fn](mgr.eUpdateCopyCur, self.UpdateCur, self)
	mgr.eUpdateCopySub[fn](mgr.eUpdateCopySub, self.UpdateSub, self)
    UIMainMenu.eHide[fn](UIMainMenu.eHide, self.SetMenuStatus, self)
    UICopyInfoTimer.eStart[fn](UICopyInfoTimer.eStart, self.CopyStart, self)
    ScreenMgr.eChange[fn](ScreenMgr.eChange, self.ScreenChange, self)
end

function M:SetEvent(e)
end

function M:ScreenChange(orient, init)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.left, nil, nil, true)
	elseif orient == ScreenOrient.Right then
		if not init then
			UITool.SetLiuHaiAnchor(self.left, nil, nil, true, true)
		end
	end
end

function M:CopyStart()
	self:StartSituFight()
end

function M:StartSituFight()
	local temp = self.Temp
	if temp and temp.id ~= User.SceneId then return end
	if Hangup:GetSituFight() == true then return end
	Hangup:SetSituFight(true)
end

function M:UpdateCopyInfo()
	local info = CopyMgr.CopyInfo
	if not info then return end
	local temp = CopyTemp[tostring(User.SceneId)]
    if temp == nil then return end
    self.Temp = temp
    self:InitData()
end



function M:OpenCustom()
	MissionMgr:Execute(false)
end


function M:ConDisplay()
	do return true end
end


function M:DisposeCustom()
    self:DisposeSelf()
    self:SetLsnr("Remove")
	self:SetLsnrSelf("Remove")
	self:SetEvent(EventMgr.Remove)
	self.Temp = nil
	CopyMgr.PlayStartTree = false
end

return M





