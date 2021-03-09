StateReCell = Super:New{Name = "StateReCell"}
local My = StateReCell

function My:Init(go)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local UC = UITool.SetLsnrClick
    local US = UITool.SetLsnrSelf

    -- local box = root:GetComponent("BoxCollider")
    -- US(box,self.ClickBox,self,name,false)
    self.nameLab = CG(UILabel,root,"nameLab",name)
    self.iconLab = CG(UILabel,root,"iconLab",name)
    self.lock = TF(root,"lock",name)
    self.icon = CG(UITexture,root,"Icon",name)
end

function My:SetActive(ac)
    self.Gbj.gameObject:SetActive(ac)
end

--id 战灵＞技能＞技能书＞天赋书（只有这4个有模型） > 战灵装备孔槽位
function My:UpdateData(id)
    local numId = id
    local id = tostring(numId)
    self.Gbj.gameObject.name = id
    local cfg = nil
    local iconPath = nil
    local itemName = nil
    local iconName = nil
    local lockAc = nil
    if SpiriteCfg[id] then
        cfg = SpiriteCfg[id]
        iconPath = cfg.mIcon
        -- itemName = string.format("战灵\n【%s】",cfg.name)
        itemName = "战灵"
        iconName = ""
        lockAc = false
    elseif SkillLvTemp[id] then
        cfg = SkillLvTemp[id]
        local baseId = tostring(cfg.baseid)
        local baseCfg = SkillBaseTemp[baseId]
        cfg = baseCfg
        iconPath = cfg.icon
        -- itemName = string.format("技能\n【%s】",cfg.name)
        itemName = "技能"
        iconName = ""
        lockAc = false
    elseif ItemData[id] and ItemData[id].type == 6 then
        cfg = ItemData[id]
        local baseId = tostring(cfg.skillBaseId[1])
        local baseCfg = SkillBaseTemp[baseId]
        cfg = baseCfg
        iconPath = ItemData[id].icon
        -- itemName = string.format("技能书\n【%s】",cfg.name)
        itemName = "技能书"
        iconName = ""
        lockAc = false
    elseif ItemData[id] and ItemData[id].type == 3 and numId > 100 then
        cfg = ItemData[id]
        iconPath = cfg.icon
        -- itemName = string.format("天赋书\n【%s】",cfg.name)
        itemName = "天赋书"
        iconName = ""
        lockAc = false
    elseif ItemData[id] and ItemData[id].type == 9 then
        cfg = ItemData[id]
        iconPath = cfg.icon
        itemName = cfg.name
        iconName = ""
        lockAc = false
    else
        cfg = ItemData["24"]
        iconPath = cfg.icon
        -- itemName = string.format("【战灵】\n装备孔解锁")
        itemName = "战灵装备孔"
        iconName = ""
        lockAc = false
    end
    self:SetCurR(iconPath)
    self.nameLab.text = itemName
    self.iconLab.text = iconName
    self.lock.gameObject:SetActive(lockAc)
end


--设置当前奖励
function My:SetCurR(iconName)
    if iconName == nil then
        return
    end
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
    self:UnLoadIcon()
    TableTool.ClearUserData(self)
end