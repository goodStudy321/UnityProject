StateItemSkill = Super:New {Name = "StateItemSkill"}

local My = StateItemSkill

function My:Init(go)
	local des = self.Name
	local root = go.transform
	
	local CG = ComTool.Get
	local TF = TransTool.Find
	local TFC = TransTool.FindChild

	self.root = root
	self.icon = CG(UITexture, root, "Icon", des)
	self.lab = CG(UILabel,root,"Lab",des)
	self.skBox = root:GetComponent(typeof(BoxCollider))
end

function My:SetActive(ac)
	self.root.gameObject:SetActive(ac)
end

function My:UpdateData(rwId,isGray)
	local id = tostring(rwId)
	local title = ""
	local name = ""
	
	-- local data = ItemData[id] ~= nil and ItemData[id] or SkillLvTemp[id]
	-- if data == nil then --战灵奖励配置
	-- 	id = rwId
	-- 	local spId = tostring(rwId/100)
	-- 	data = SpiriteCfg[spId]
	-- end
	if SpiriteCfg[id] then
		data = SpiriteCfg[id]
		title = "战灵"
	elseif ItemData[id] ~= nil and ItemData[id].type == 6 then
		data = ItemData[id]
		title = "技能书"
	elseif ItemData[id] ~= nil and ItemData[id].type == 3 and rwId > 50 then
		data = ItemData[id]
		title = "天赋书"
	elseif SkillLvTemp[id] ~= nil then
		data = SkillLvTemp[id]
		title = "技能"
	else
		data = ItemData["24"]
		title = "战灵孔"
	end
	local baseId = nil
	if data.skillBaseId then
		baseId = data.skillBaseId[1]
	elseif data.baseid then
		baseId = data.baseid
	end
	if baseId == nil and ItemData[id] ~= nil and ItemData[id].type == 3 and rwId > 50 then
		baseId = id
	end
	if baseId == nil then
		baseId = data.spiriteId
	end
	if baseId == nil then
		baseId = 24 --战灵装备孔
	end
	baseId = tostring(baseId)
	local baseSkCfg = SkillBaseTemp[baseId] or SpiriteCfg[baseId] or ItemData[baseId]
	if baseSkCfg == nil then
		iTrace.eError("GS","请检查奖励配置")
		return
	end
	name = baseSkCfg.name
	if tonumber(id) < 50 then
		id = 24
	end
	self.root.gameObject.name = id
	local iconPath = data.icon or data.mIcon
	self:SetCurR(iconPath)
	self:SetName(title,name,isGray)
end

function My:SetName(title,name,isGray)
	local str = ""
	local color1 = ""
	local color2 = ""
	if isGray == true then
		color1 = "[B2ADAD]"
		color2 = "[B2ADAD]"
	else
		color1 = "[F4DDBDFF]"
		color2 = "[F4DDBDFF]"
	end
	str = string.format("%s%s[-]",color1,title)
	-- str = string.format("%s%s[-]%s%s【%s】[-]",color1,title,"\n",color2,name)
	self.lab.text = str
end

--设置当前奖励
function My:SetCurR(iconName)
    AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
end

--// 读取图标完成
function My:LoadIconFin(obj)
    self.icon.mainTexture = obj
    self.iconName = self.icon.mainTexture.name
end

function My:UnLoadIcon()
    if self.iconName == nil then
        return
    end
    AssetTool.UnloadTex(self.iconName)
    self.iconName = nil
end

function My:Dispose()
	TableTool.ClearUserData(self)
end
