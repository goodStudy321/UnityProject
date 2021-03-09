SuitSkillTip = {Name = "SuitSkillTip"}
local My = SuitSkillTip;

function My:Init(root)
	self.root = root
	self.gbj = root.gameObject
	local des = self.Names
	local CG = ComTool.Get
    local TFC = TransTool.FindChild
    local UC = UITool.SetLsnrClick;

	local tr = TransTool.Find(root, "bg", des)
	self.icon = CG(UITexture, tr, "icon", des)
	self.nameLbl = CG(UILabel, tr, "name", des)
	self.lvLbl = CG(UILabel, tr, "lv", des)
	self.desLbl = CG(UILabel, tr, "des", des)
	UC(root,"Container",name,self.Close,self);
    self.bgTran = tr
    self:SetActive(false)
end

--显示提示
--it(UISkillItem)
function My:Show(skLvId,icon)
    self:SetActive(true);
	self:ShowByLvID(skLvId, icon)
end

--显示提示
--lvID(number):等级ID
--icon:图片名
function My:ShowByLvID(lvID, icon)
	local strLvID = tostring(lvID)
	self.iconName = icon
	local lvCfg = SkillLvTemp[strLvID]
	local skillId = tostring(lvCfg.baseid)
	self.desLbl.text = lvCfg.desc
	self.nameLbl.text = lvCfg.name
    self.lvLbl.text = lvCfg and tostring(lvCfg.level) or "no"
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

function My:SetIcon(tex)
    if self.icon then
        self.icon.mainTexture = tex;
    end
end

function My:ClearIcon()
	if self.iconName then
		AssetMgr:Unload(self.iconName,false)
		self.iconName = nil
	end
end

function My:Close()
	self:SetActive(false)
end

function My:SetActive(active)
    if self.gbj == nil then
        return;
    end
    self.gbj:SetActive(active)
end

function My:Dispose()
    if self.root == nil then
        return;
    end
    self.root = nil
    self.gbj = nil;
    self:Close()
	self:ClearIcon()
	TableTool.ClearUserData(self)
end

return My