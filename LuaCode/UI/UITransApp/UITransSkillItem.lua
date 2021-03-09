UITransSkillItem = Super:New {Name = "UITransSkillItem"}

local My = UITransSkillItem

function My:Init(root, lvID, cntr)
	local des = self.Name
	root.name = tostring(lvID)
	self.root = root
	--技能等级配置ID
	self.lvID = lvID
	self.cntr = cntr
	self.icon = ComTool.Get(UITexture, root, "icon", des)
	--锁
	self.lockGbj = TransTool.FindChild(root, "lock", des)

	UITool.SetBtnClick(root, "icon", des, self.OnClick, self)
	self:LoadIcon()
end

--加载图标
function My:LoadIcon()
	local k = tostring(self.lvID)
	local cfg = SkillLvTemp[k]
	if cfg == nil then
		iTrace.Error("Loong", "无技能等级配置, id:" .. k)
	else
		AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
	end
end

--加载图标回调
function My:SetIcon(obj)
	self.icon.mainTexture = obj
	self.texName = obj.name
end

--清理texture
function My:ClearIcon()
	if self.texName then
        AssetMgr:Unload(self.texName, ".png", false)
        self.texName = nil
    end
end

--lt(boolean):true锁定
--id(技能等级配置ID)
function My:Refresh(lt, lvID)
	lvID = lvID or self.id
	if lvID ~= self.id then
		-- self:ClearIcon()
		self.lvID = lvID
		self:LoadIcon()
		self.root.name = tostring(lvID)
	end
	lt = lt or false
	self:Lock(lt)
end

function My:Lock(at)
	self.lockGbj:SetActive(at)
	self.lock = at or false
end

function My:OnClick()
	if type(UISpSkill.Switch) == "function" then
		UISpSkill:Switch(self)
	end
end

function My:Dispose()
	self:ClearIcon()
	self.lvID = 0
	self.lock = false
	TableTool.ClearUserData(self)
end
