--[[
 	authors 	:Liu
 	date    	:2018-11-1 15:10:00
 	descrition 	:仙魂佩戴界面（佩戴格子）
--]]

UIImmSoulWearIt = Super:New{Name = "UIImmSoulWearIt"}

local My = UIImmSoulWearIt

function My:Init(root, isLock, needLv, index)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    
    SetB(root, "cell", des, self.OnClick, self)
    self.tex = CG(UITexture, root, "cell/icon")
    self.lab = CG(UILabel, root, "lab")
    self.cellLab = CG(UILabel, root, "cell/lab")
    self.cellBg = CG(UISprite, root, "cell/cellBg")
    self.lock = FindC(root, "cell/lock", des)
    self.action = FindC(root, "cell/Action", des)
    self.go = root.gameObject
    self.isLock = isLock
    self.needLv = needLv
    self.index = index
    self.isAction = false
    self.isDress = false
    self:InitLock(isLock)
end

--更新数据
function My:SetData(cfg, icon, isDress)
    self:UnloadTex()
    self.cfg = cfg
    self.isDress = isDress
    self.texName = icon
    self:SetLab(cfg.name, cfg.lv)
    self:UpIcon(true)
    self:SetCellBg(cfg)
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

--仙魂升级时更新配置信息
function My:UpCfg(cfg)
    self.cfg = cfg
end

--设置格子背景
function My:SetCellBg(cfg)
    local bg = self.cellBg
    bg.gameObject:SetActive(true)
    local qua = math.floor(cfg.id % 10)
    local str = ImmortalSoulInfo:GetCellBg(qua)
    bg.spriteName = str
end

--设置Icon
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--更新贴图显示
function My:UpIcon(state)
    self.tex.gameObject:SetActive(state)
end

--设置文本
function My:SetLab(str, lv)
    self.lab.text = str
    local state = (lv ~= nil)
    self.cellLab.gameObject:SetActive(state)
    if state then
        self.cellLab.text = "Lv."..lv
    end
end

--更新等級文本
function My:UpLvLab(lvId)
    local cfg, temp = BinTool.Find(ImmSoulLvCfg, lvId)
    if cfg == nil then return end
    self.cellLab.text = "Lv."..cfg.lv
end

--点击
function My:OnClick(go)
    if self.isLock then
        local str = string.format("该位置%s级开启", self.needLv)
        UITip.Log(str)
    end
    if self.isDress then
        UIImmortalSoul:ShowTip(self.cfg, 2, self.index)
    end
end

--设置锁
function My:InitLock(state)
    self.lock:SetActive(state)
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
    self.cfg = nil
    self.isDress = false
    self.cellBg.gameObject:SetActive(false)
    local str = (self.index < 907) and "普通" or "核心"
    self:SetLab(str)
    self:UnloadTex()
end

--更新显示红点
function My:UpShowAction()
    local isOne, isTwo = ImmortalSoulInfo:GetActionList()
    if self.index < 907 then
        self.isAction = isOne
    else
        self.isAction = isTwo
    end
    self:SetAction(self.isAction)
end

--设置红点
function My:SetAction(state)
    self.action:SetActive(state)
end

--清理缓存
function My:Clear()
    self.go = nil
    self.id = nil
    self:UnloadTex()
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My