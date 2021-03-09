--[[
 	authors 	:Liu
 	date    	:2019-07-01 12:00:00
 	descrition 	:商店模块项
--]]

UIActivSDIt = Super:New{Name = "UIActivSDIt"}

local My = UIActivSDIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
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
    self:UpItem()
    self:UpBtnState()
end

--更新数据
function My:UpData()
    self:UpCellCount()
    self:UpBtnState()
    self:UpItem()
end

--点击兑换
function My:OnBtn()
    LimitActivMgr:ReqBuy(self.cfg.id)
end

--显示按钮状态
function My:UpBtnState()
    local str = ""
    if self:IsBuy() then
        str = "btn_figure_non_avtivity"
        CustomInfo:SetBtnState(self.btn, true)
    else
        str = "btn_figure_down_avtivity"
        CustomInfo:SetBtnState(self.btn, false)
    end
    self.btnSpr.spriteName = str
end

--判断是否能兑换
function My:IsBuy()
    local cfg = self.cfg
    local id = cfg.buyItem
    local count = ItemTool.GetNum(id)
    local isBuy = count >= cfg.buyCount
    
    local num = LimitActivInfo:GetCount(cfg.id)
    local isMax = ((cfg.maxCount - num) <= 0)

    return isBuy and (not isMax)
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
    local item = cfg.showItem[1]
    if item == nil then return end
    local num = LimitActivInfo:GetCount(cfg.id)
    local count = cfg.maxCount - num
    local str = string.format("%s/%s", count, cfg.maxCount)
    self.cell:UpData(item.k, str)
    self:UpName(item.k)
end

--更新道具名字
function My:UpName(id)
    local item = ItemData[tostring(id)]
    if item == nil then return end
    self.lab1.text = item.name
end

--初始化兑换道具
function My:UpItem()
    local cfg = self.cfg
    local id = cfg.buyItem
    local item = ItemData[tostring(id)]
    if item == nil then return end
    local count = ItemTool.GetNum(id)
    local color = (count<cfg.buyCount) and "[F21919FF]" or "[-]"
    local str = string.format("%s%s[-]/%s", color, count, cfg.buyCount)

    self.lab2.text = str
    if self.texName and self.texName == item.icon then return end
    self.texName = item.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--初始化名字
function My:InitName()
    self.go.name = self.cfg.id + 100
end

--清空道具
function My:ClearCell()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

--清理缓存
function My:Clear()
    self:ClearCell()
end

--释放资源
function My:Dispose()
    self:Clear()
    AssetMgr:Unload(self.texName,false)
    self.texName = nil
end

return My