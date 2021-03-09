UIThSkilTip = Super:New {Name = "UIThSkilTip"}

local My = UIThSkilTip


function My:Ctor()
	--技能条目列表
	self.items = {}
end

function My:Init(root)
	self.root = root
	self.gbj = root.gameObject
	local des = self.Names
	local CG = ComTool.Get
	local TFC = TransTool.FindChild
	local tr = TransTool.Find(root, "bg", des)
	self.icon = CG(UITexture, tr, "icon", des)
	self.nameLbl = CG(UILabel, tr, "name", des)
	self.lvLbl = CG(UILabel, tr, "lv", des)
	self.desLbl = CG(UILabel, tr, "des", des)
	self.limitLbl = CG(UILabel, tr, "limitLab", des)
	self.lockedGo = TFC(tr, "locked", des)
	self.unlockGo = TFC(tr, "unlock", des)
	UITool.SetBtnSelf(self.gbj, self.Close, self, nil, false)
	self.bgTran = tr
end

--显示提示
--it(UISkillItem)
function My:Show(it)
	local root = it.root
	local pos = root and root.position or nil
	pos.y = pos.y + 100 * 0.0026
	self:ShowByLvID(it.lvID, it.icon.mainTexture, it.lock, pos)
end

--显示提示
--lvID(number):等级ID
--iconTex(texture):图片
--lock(boolean):true:未解锁
--pos(Vector3):位置
function My:ShowByLvID(lvID, iconTex, lock, pos)
	local strLvID = tostring(lvID)
	self.icon.mainTexture = iconTex
	self.iconName = iconTex.name
	local lvCfg = SkillLvTemp[strLvID]
	local skillId = tostring(lvCfg.baseid)
	local limitDes = SkillBaseTemp[skillId].unlockDes
	self.desLbl.text = lvCfg.desc
	self.limitLbl.text = limitDes
	self.nameLbl.text = lvCfg.name
	self.lvLbl.text = lvCfg and tostring(lvCfg.level) or "no"
	self.gbj:SetActive(true)
	self.unlockGo:SetActive(lock)
	self.lockedGo:SetActive(not lock)
	if pos == nil then return end

	-- self.bgTran.position = pos
end

--显示技能类型
function My:GetTypeStr(ty)
	if ty == 0 then
		return "普通技能"
	elseif ty == 1 then
		return "主动技能"
	elseif ty == 2 then
		return "被动技能"
	else
		return "无技能类型:" .. tostring(ty)
	end
end

function My:ClearIcon()
	if self.iconName then
		-- iTrace.Error("GS","技能提示释放===",self.iconName)
		AssetMgr:Unload(self.iconName,".png",false)
		self.iconName = nil
	end
end

function My:Close()
	self.gbj:SetActive(false)
end

function My:Dispose()
	self:ClearIcon()
	TableTool.ClearUserData(self)
end

return My
