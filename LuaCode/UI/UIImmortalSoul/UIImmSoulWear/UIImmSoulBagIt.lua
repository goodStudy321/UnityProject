--[[
 	authors 	:Liu
 	date    	:2018-11-1 15:10:00
 	descrition 	:仙魂佩戴界面（背包格子）
--]]

UIImmSoulBagIt = Super:New{Name = "UIImmSoulBagIt"}

local My = UIImmSoulBagIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    
    SetS(root, self.OnClick, self, des, false)
    self.tex = CG(UITexture, root, "icon")
    self.cellBg = CG(UISprite, root, "cellBg")
    self.lab = CG(UILabel, root, "lab")
    self.col = CGS(BoxCollider, root, des)
    self.select = FindC(root, "select", des)
    self.root = root
    self.go = root.gameObject
    self.eff = nil
    self:UpBoxCollider(false)
end

--点击
function My:OnClick(go)
    if not self:IsCfg() then return end
    UIImmortalSoul:ShowTip(self.cfg, 1, self.cellId)
end

--判断配置是否存在
function My:IsCfg()
    if self.cfg == nil then return false end
    local cfg, temp = BinTool.Find(ImmSoulLvCfg, self.cfg.id)
    if cfg == nil then return false end
    return true
end

--设置数据
function My:SetData(cfg, icon, cellId)
    self:UnloadTex()
    self.cfg = cfg
    self.cellId = cellId
    self.texName = icon
    self:UpIcon(true)
    self:SetLab(cfg)
    self:SetCellBg(cfg)
    self:UpBoxCollider(true)
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

--设置格子背景
function My:SetCellBg(cfg)
    local bg = self.cellBg
    bg.gameObject:SetActive(true)
    self.select:SetActive(true)
    local qua = math.floor(cfg.id % 10)
    local str = ImmortalSoulInfo:GetCellBg(qua)
    bg.spriteName = str
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--更新贴图显示
function My:UpIcon(state)
    self.tex.gameObject:SetActive(state)
end

--设置等级文本
function My:SetLab(cfg)
    self.lab.gameObject:SetActive(true)
    self.lab.text = "Lv."..cfg.lv
end

--更新碰撞器
function My:UpBoxCollider(state)
    self.col.enabled = state
end

--改变自身名字
function My:ChangeName(cellId)
    self.id = cellId
    self.go.name = cellId
end

--卸载贴图
function My:UnloadTex()
    if self.texName then
        AssetMgr:Unload(self.texName, false)
        self.texName = nil
    end
end

--清空配置
function My:ClearCfg()
    self:UpBoxCollider(false)
    self.cellBg.gameObject:SetActive(false)
    self.lab.gameObject:SetActive(false)
    self.select:SetActive(false)
    self:ClearEff()
    self.cfg = nil
    self:UnloadTex()
end

--清空特效
function My:ClearEff()
    if self.eff then
        self.effName = self.eff.name..".prefab"
        AssetMgr:Unload(self.effName,false)
        Destroy(self.eff)
        self.eff = nil
    end
end

--清理缓存
function My:Clear()
    self.cfg = nil
    self.id = nil
    self:UnloadTex()
    AssetMgr:Unload(self.effName,false)
end

--释放资源
function My:Dispose()
    self:Clear()
    self:ClearEff()
end

return My