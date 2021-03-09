--[[
 	authors 	:Liu
 	date    	:2019-2-13 16:00:00
 	descrition 	:亲密商店项
--]]

UIActSDItem = Super:New{Name = "UIActSDItem"}

local My = UIActSDItem

function My:Init(root, cfg, index)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.index = index
    self.go = root.gameObject
    self.btn = FindC(root, "btn", des)
    self.parent = Find(root, "cell", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.tex = CG(UITexture, root, "icon")
    self.btnSpr = CG(UISprite, root, "btn")

    SetB(root, "btn", des, self.OnBtn, self)

    self:InitName()
    self:InitCell()
    self:InitIcon()
    self:InitNameLab()
    self:UpIconCount()
    self:UpBtnState()
end

--点击兑换
function My:OnBtn()
    local cfg = self.cfg
    local id = FestivalActInfo.itemId
    local count = ItemTool.GetNum(id)
    if cfg.schedule == 0 or count < cfg.remainCount then return end
    local mgr = FestivalActMgr
    mgr:ReqBgActReward(self.cfg.type, self.cfg.id)
end

--显示按钮状态
function My:UpBtnState()
    local cfg = self.cfg
    local id = FestivalActInfo.itemId
    local count = ItemTool.GetNum(id)
    if cfg.schedule == 0 then
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
    elseif count < cfg.remainCount then
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
    else
        self.btnSpr.spriteName = "btn_figure_non_avtivity"
    end
end

--更新道具
function My:InitCell()
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.parent, 0.8)
    self:UpCellCount()
end

--更新道具数量
function My:UpCellCount()
    local cfg = self.cfg
    local item = cfg.rewardList[1]
    if item == nil then return end
    local str = string.format("%s/%s", cfg.schedule, cfg.target)
    self.cell:UpData(item.id, str, item.effNum==1)
end

--初始化兑换道具
function My:InitIcon()
    local id = FestivalActInfo.itemId
    if id == 0 then return end
    local cfg = ItemData[tostring(id)]
    if cfg == nil then return end
    self.texName = cfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--初始化兑换道具的数量
function My:UpIconCount()
    local id = FestivalActInfo.itemId
    local count = ItemTool.GetNum(id)
    local str = string.format("%s/%s", count, self.cfg.remainCount)
    self.lab2.text = (self.index==0) and str or self.cfg.remainCount
end

--初始化道具名字
function My:InitNameLab()
    local item = self.cfg.rewardList[1]
    if item == nil then return end
    local key = tostring(item.id)
    local cfg = ItemData[key]
    if cfg == nil then return end
    self.lab1.text = cfg.name
end

--初始化名字
function My:InitName()
    self.go.name = self.cfg.id + 100
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    self:Clear()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
    AssetMgr:Unload(self.texName,false)
end

return My