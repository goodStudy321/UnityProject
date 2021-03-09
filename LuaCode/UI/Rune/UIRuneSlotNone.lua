--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-03-26 16:13:39
--=========================================================================

UIRuneSlotNone = Super:New{ Name = "UIRuneSlotNone" }

local My = UIRuneSlotNone


function My:Init(root)
	self.go = root.gameObject
	local des = self.Name
	local USC = UITool.SetLsnrClick
	USC(root, "getBtn", des, self.OnClickGet, self)
	USC(root, "bagBtn", des, self.OnClickBag, self)
	local getPathTran = TransTool.Find(root, "getPath", des)
	USC(getPathTran, "kxtBtn", des, self.OnClickKXT, self)
	USC(getPathTran, "runeBtn", des, self.OnClickRune, self)
	USC(getPathTran, "close", des, self.DisableGetPath, self)
	self.getPathGo = getPathTran.gameObject
	self:SetGetPathActive(false)
end

function My:OnClickBag()
	UIRune.embed.bag:Open()
end

function My:OnClickGet()
	self:SetGetPathActive(true)
end

function My:OnClickKXT()
	local isOpen = UITabMgr.IsOpen(ActivityMgr.TTT)
	if isOpen then
		JumpMgr:InitJump("UIRune", 1)
		UIMgr.Open("UICopyTowerPanel")
	else
		UITip.Log("系统未开启")
	end
end

function My:OnClickRune()
	JumpMgr:InitJump("UIRune", 1)
	UITreasure:OpenTab(2)
end

function My:SetActive(at)
	self.go:SetActive(at)
end

function My:DisableGetPath()
	self:SetGetPathActive(false)
end

function My:SetGetPathActive(at)
	self.getPathGo:SetActive(at)
	self.getPathAt = at
end

function My:RespEmbed()
	self:Close()
end

function My:Close()
	self:SetActive(false)
	self:SetGetPathActive(false)
end

function My:Open()
	self:SetActive(true)
end

function My:Dispose()
	TableTool.ClearUserData(self)
end


return My