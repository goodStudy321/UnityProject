--[[
 	authors 	:Liu
 	date    	:2018-11-7 19:10:00
 	descrition 	:仙魂合成界面（弹窗项）
--]]

UIImmSoulCompPopIt = Super:New{Name = "UIImmSoulCompPopIt"}

local My = UIImmSoulCompPopIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local SetS = UITool.SetLsnrSelf

    SetS(root, self.OnClick, self, des, false)
    self.tex = CG(UITexture, root, "icon")
    self.lab = CG(UILabel, root, "lab")
    self.cellBg = CG(UISprite, root, "cellBg")
    self.tog = CGS(UIToggle, root, des)
    self.col = CGS(BoxCollider, root, des)
    self.go = root.gameObject
    self:UpBoxCollider(false)
end

--点击
function My:OnClick(go)
    if not self:IsCfg() then return end
    local it = UIImmortalSoul
    it:ShowTip(self.cfg, 3, self.cellId)
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

--设置文本
function My:SetLab(cfg)
    self.lab.gameObject:SetActive(true)
    self.lab.text = "Lv."..cfg.lv
end

--设置Tog
function My:SetTog()
    self.tog.value = true
end

--更新碰撞器
function My:UpBoxCollider(state)
    self.col.enabled = state
end

--改变自身名字
function My:ChangeName(cellId)
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
    self.cfg = nil
    self.tog.value = false
    self:UpBoxCollider(false)
    self.cellBg.gameObject:SetActive(false)
    self.lab.gameObject:SetActive(false)
    self:UnloadTex()
end

--清理缓存
function My:Clear()
    self:UnloadTex()
end

--释放资源
function My:Dispose()
    self:Clear()
    if self.go then
        Destroy(self.go)
    end
end

return My