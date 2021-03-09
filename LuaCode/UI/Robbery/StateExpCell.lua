StateExpCell = Super:New{Name = "StateExpCell"}
local My = StateExpCell

function My:Init(go)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local UC = UITool.SetLsnrClick
    local US = UITool.SetLsnrSelf

    self.light = TF(root,"light",name)
    self.lock = TF(root,"lock",name)
    self.icon = CG(UITexture,root,"Icon",name)
end

function My:SetActive(ac)
    self.Gbj.gameObject:SetActive(ac)
end

function My:UpdateData(spCfg)
    local id = spCfg.spiriteId
    local curSpId = RobberyMgr.curSpiId
    if curSpId == nil or curSpId <=0 then
        curSpId = 0
    end
    local numId = id
    local id = tostring(numId)
    self.Gbj.gameObject.name = id
    local iconPath = nil
    iconPath = spCfg.mIcon
    self:SetCurR(iconPath)
    self.lock.gameObject:SetActive(numId > curSpId)
    self.light.gameObject:SetActive(curSpId >= numId)
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