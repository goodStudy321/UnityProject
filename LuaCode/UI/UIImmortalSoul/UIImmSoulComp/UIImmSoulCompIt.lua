--[[
 	authors 	:Liu
 	date    	:2018-11-2 19:10:00
 	descrition 	:仙魂合成界面（合成项）
--]]

UIImmSoulCompIt = Super:New{Name = "UIImmSoulCompIt"}

local My = UIImmSoulCompIt

function My:Init(root)
	local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local SetS = UITool.SetLsnrSelf

    SetS(root, self.OnClick, self, des, false)
    self.lock = FindC(root, "lock", des)
    self.countBg = FindC(root, "countBg", des)
    self.tex = CG(UITexture, root, "icon")
    self.cellBg = CG(UISprite, root, "cellBg")
    self.lab = CG(UILabel, root, "countBg/lab")
    self.root = root
    self.go = root.gameObject
    self.id = 0
    self.effName = ""
    self.effList = {}
end

--点击
function My:OnClick()
    local info = ImmortalSoulInfo
    local id = self.id
    local cfg, temp = BinTool.Find(ImmSoulLvCfg, id)
    if cfg == nil then return end
    if self.index == 4 then
        local it = UIImmortalSoul
        it:ShowTip(self.cfg, 3, 0)
    else
        local list = info:GetIdList(id)
        local len = (info:GetId(id)==nil) and #list or #list + 1
        if len < 1 then
            local str = string.format("%s，数量不足", cfg.name)
            UITip.Log(str)
            return
        end
        UIImmortalSoul.mod2.pop:UpShow(true, id, self.index)
    end
end

--更新数据
function My:UpData(num, index, cfg)
    self.index = index
    self.cfg = cfg
    local state = false
    if num == 0 then state = true end
    self:SetState(state)
    local key = tostring(num)
    local cfg = ImmSoulCfg[key]
    if cfg then
        self.texName = cfg.icon
        AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
        self:SetCellBg(cfg)
        local info = ImmortalSoulInfo
        local list = info:GetIdList(num)
        local len = (info:GetId(num)==nil) and #list or #list + 1
        local str = string.format("%s/1", len)
        self.lab.text = str
        self.id = num
    else
        if index == 2 then
            AssetMgr:Load("15.png", ObjHandler(self.SetIcon, self))
            self:UpStone(num)
        end
    end
    if index == 4 then
        self.countBg:SetActive(false)
    end
end

--更新仙魂石
function My:UpStone(num)
    if not self.cell then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.root, 0.8)
    end
    local id = 15
    self.cell:UpData(id, 1, false)
    self.cellBg.gameObject:SetActive(true)
    local info = ImmortalSoulInfo
    local str = string.format("%s/%s", info.stone, num)
    self.lab.text = str
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

--设置状态
function My:SetState(isLock)
    self.cellBg.gameObject:SetActive(false)
    if isLock then
        UITool.SetGray(self.go)
    else
        UITool.SetNormal(self.go)
    end
    self.lock:SetActive(isLock)
    self.countBg:SetActive(not isLock)
    self.tex.gameObject:SetActive(not isLock)
end

--卸载贴图
function My:UnloadTex()
    if self.texName then
        AssetMgr:Unload(self.texName, false)
        self.texName = nil
    end
end

--清理缓存
function My:Clear()
    self:UnloadTex()
    self:UnloadEff(self.effList)
	self.effList = {}
end

--卸载特效
function My:UnloadEff(list)
	local num = #list
    for i=1, num do
        local it = list[#list]
        if it then
            AssetMgr:Unload(self.effName, false)
			Destroy(it)
			table.remove(list, #list)
		end
	end
end

--释放资源
function My:Dispose()
    self:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return My