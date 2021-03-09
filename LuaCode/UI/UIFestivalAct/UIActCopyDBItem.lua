UIActCopyDBItem = Super:New{Name = "UIActCopyDBItem"}

local M = UIActCopyDBItem

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    
    self.go = go
    self.des = G(UILabel, trans, "Des")
    self.icon = G(UITexture, trans, "Icon")

    UITool.SetLsnrClick(trans, "Btn", self.Name, self.OnClick, self)
end

function M:OnClick()
    local copyType = self.data.remainCount
    if copyType == CopyType.Exp 
    or copyType == CopyType.Glod 
    or copyType == CopyType.SingleTD 
    or copyType == CopyType.XH  
    or copyType == CopyType.ZLT 
    or copyType == CopyType.Equip 
    or copyType == CopyType.Five 
    then
        local _, isOpen, _, lv = CopyMgr:GetCurCopy(copyType)
        if not isOpen then 
            UITip.Log(string.format("%s开启", UserMgr:chageLv(lv)))
            return 
        end
        UICopy:Show(copyType)
    elseif copyType == CopyType.Loves then
        UIMarry:OpenTab(2)
    end
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:UpdateDes()
    self.des.text = self.data.des
end

function M:UpdateIcon()
    local type = self.data.remainCount
    local texture =  "sys_41"
    if type == CopyType.Exp then
        texture = "sys_41"
    elseif type == CopyType.Glod then
        texture = "sys_16"
    elseif type == CopyType.Equip then
        texture = "sys_11"
    elseif type == CopyType.SingleTD then
        texture = "sys_26"
    elseif type == CopyType.XH then
        texture = "sys_22"
    end
    AssetMgr:Load(texture..".png",ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:UpdateData(data)
    self.data = data
    self:UpdateDes()
    self:UpdateIcon()
end

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
end

return M