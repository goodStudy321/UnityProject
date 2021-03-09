

UIWorldBossBtn = Super:New{Name = "UIWorldBossBtn"}

local M = UIWorldBossBtn

local aMgr = ActivityMgr

function M:Init(root, parent)
	self.Root = root
	self.Parent = parent
	self.Eff = nil
	if parent then
		local bg = parent.BgSprite
		local name = parent.Name
		local box = parent.BgBox
		local active = parent.Action
		if bg then
			bg.spriteName = ""
		end
		if name then
			name.gameObject:SetActive(false)
		end
		if box then
			box.size = Vector3.New(75,172,0)
		end
		if active then
			active.transform.localPosition = Vector3.New(34,68,0)
		end 
	end
	self:CheckOpen()
end

function M:CheckOpen()
	local isOpen = aMgr:CheckOpenForLvId(aMgr.BOSS)
	if isOpen == true then
		self:ShowOpenEffect()
	end
	
	if self.Parent then
		local icon = self.Parent.Icon
		if icon then
			if isOpen == true then
				icon.spriteName = "dabao_1"
			else
				icon.spriteName = "dabao_2"
			end
			icon:MakePixelPerfect()
		end
	end
end

function M:ShowOpenEffect()
	if LuaTool.IsNull(self.Eff) == false then return end
	Loong.Game.AssetMgr.LoadPrefab("UI_db_01", GbjHandler(self.LoadEffectEnd,self))
end

function M:LoadEffectEnd(go)
	local root = self.Root
	if not root or LuaTool.IsNull(self.Eff) == false then
		Destroy(go)
		return 
	end
	self.Eff = go
	go.transform:SetParent(root.transform)
	go.transform.localPosition = Vector3.New(0,45.44,0)
	go.transform.localScale = Vector3.one
	local eff = go:AddComponent(typeof(UIEffBinding))
	if self.Parent and self.Parent.Icon then
		eff.specifyWidget = self.Parent.Icon
	end
	go:SetActive(true)
end
    
--释放资源
function M:Dispose()
	local parent = self.Parent
	if parent then
		local bg = parent.BgSprite
		local name = parent.Name
		local box = parent.BgBox
		local active = parent.Action
		if bg then
			bg.spriteName = "activity-bg"
		end
		if name then
			name.gameObject:SetActive(true)
		end
		if box then
			box.size = Vector3.New(74,74,0)
		end
		if active then
			active.transform.localPosition = Vector3.New(24.5,22.6,0)
		end 
	end
	if self.Eff then
		Destroy(self.Eff)
	end
	self.Eff = nil
end

return M