local base = require("UI/Robbery/SpiriteModItem")

UIListSpModItem = SpiriteModItem:New{Name = "UIListSpModItem"}

local My = UIListSpModItem

function My:Init(root)
    self.root = root
    local TFC = TransTool.FindChild
    local CG, des = ComTool.Get, self.Name
    --名称标签
    self.nameLbl = CG(UILabel, root, "name", des)
    self.lockLbl = CG(UILabel, root, "lockLab", des)
    --图标贴图
    self.iconTex = CG(UITexture, root, "icon", des)

    --高亮(选中时改变)
    self.hlGo = TFC(root, "hl", des)
    self.hlGo:SetActive(false)

    --红点设置
    self.actionGo = TFC(root, "action", des)
    self.actionGo:SetActive(false)

    self.lockGo = TFC(root, "lock", des)

    -- self:SetLock()
end

function My:InitData(info)
    self:LoadIcon(info)
    self.nameLbl.text = info.name
    local lockState = info.lockState
    local curCfg = RobberyMgr:GetCurCfg(lockState)
    self.lockLbl.text = string.format("%s开启", curCfg.floorName)
end


function My:SetLock(ac)
    self.lockGo:SetActive(ac)
    if ac == false then
        self.lockLbl.text = ""
    end
end

function My:LoadIcon(info)
    AssetMgr:Load(info.mIcon, ObjHandler(self.SetIcon, self))
end

function My:SetIcon(tex)
    if not LuaTool.IsNull(self.iconTex) then
        self.iconTex.mainTexture = tex
        self.texName = tex.name
    end
end

function My:SetRed(state)
    self.actionGo:SetActive(state)
end

function My:ClearIcon()
    if self.texName then
        AssetMgr:Unload(self.texName,".png",false)
        self.texName = nil
    end
end

function My:IsSelect(at)
    self.hlGo:SetActive(at)
end

function My:Dispose()
    self:ClearIcon()
    base:Dispose()
    TableTool.ClearUserData(self)
end

return My