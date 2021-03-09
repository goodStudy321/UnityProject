--[[
  authors 	:Loong
 	date    	:2017-08-23 14:27:57
 	descrition 	:技能条目
--]]
UISkillItem = Super:New {Name = "UISkillItem"}

local My = UISkillItem

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

--加载图表回调
function My:SetIcon(obj)
	if LuaTool.IsNull(self.icon) then
		return
	end
	self.icon.mainTexture = obj
	self.texName = obj.name
end

--清理texture
function My:ClearIcon()
	if self.texName then
		-- iTrace.Error("GS","技能资源释放===",self.texName)
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
	if type(self.cntr.Switch) == "function" then
		self.cntr:Switch(self)
	end
end

function My:Dispose()
	self:ClearIcon()
	self.cntr = nil
	self.lvID = 0
	self.lock = false
	TableTool.ClearUserData(self)
end
