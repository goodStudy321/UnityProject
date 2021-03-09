--[[
 	authors 	:Liu
 	date    	:2019-3-22 17:10:00
 	descrition 	:限时抢购项
--]]

UITimeLimitBuyIt = Super:New{Name="UITimeLimitBuyIt"}

local My = UITimeLimitBuyIt

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.go = root.gameObject
    self.item = Find(root, "item", des)
    self.btn = FindC(root, "btn", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.priceSpr1 = CG(UISprite, root, "price1")
    self.priceSpr2 = CG(UISprite, root, "price2")
    self.priceLab1 = CG(UILabel, root, "price1/lab")
    self.priceLab2 = CG(UILabel, root, "price2/lab")

    SetB(root, "btn", des, self.OnBuy, self)
end

--点击购买
function My:OnBuy()
    local cfg = self.cfg
    local gold = RoleAssets.Gold
    local bindGold = RoleAssets.BindGold
    if cfg.goldType == 2 then
        if gold < cfg.cPrice then
            StoreMgr.JumpRechange()
            JumpMgr:InitJump(UITimeLimitBuy.Name)
            return
        end
    elseif cfg.goldType == 3 then
        if bindGold < cfg.cPrice then
            UITip.Log("绑定元宝不足")
            return
        end
    end
    TimeLimitActivMgr:ReqBuy(self.cfg.id)
end

--更新数据
function My:UpData(cfg)
    self.cfg = cfg
    self:UpLab(cfg)
    self:UpSpr(cfg)
    self:UpCell(cfg)
end

--更新按钮
function My:UpBtnState(count)
    local cfg = self.cfg
    local num = (count) and cfg.buyCount - count or cfg.buyCount
    local color = (num<1) and "[F21919FF]" or "[E5B45FFF]"
    self.lab2.text = string.format("[E5B45FFF]限购:%s%s[-]/%s", color, num, cfg.buyCount)
    if num > 0 then
        UITool.SetNormal(self.btn)
        self:UpName(1000)
    else
        UITool.SetGray(self.btn)
        self:UpName(5000)
    end
end

--更新名字
function My:UpName(num)
    self.go.name = self.cfg.id + num
end

--更新文本
function My:UpLab(cfg)
    local id = cfg.item[1].I
    local info = ItemData[tostring(id)]
    if info == nil then return end
    self.lab1.text = info.name
    self.priceLab1.text = cfg.oPrice
    self.priceLab2.text = cfg.cPrice
end

--更新元宝贴图
function My:UpSpr(cfg)
    local str = (cfg.goldType==2) and "money_02" or "money_03"
    self.priceSpr1.spriteName = str
    self.priceSpr2.spriteName = str
end

--更新道具
function My:UpCell(cfg)
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.item, 0.9)
    end
    local it = cfg.item[1]
    self.cell:UpData(it.I, it.B)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    if self.cell then
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil
	end
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My