--[[
 	authors 	:Liu
 	date    	:2019-1-18 21:00:00
 	descrition 	:开服冲榜购买项
--]]

UIRankBuyItem = Super:New{Name = "UIRankBuyItem"}

local My = UIRankBuyItem

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.num = 0
    self.go = root.gameObject
    self.spr1 = CG(UISprite, root, "lab1/spr")
    self.spr2 = CG(UISprite, root, "lab2/spr")
    self.nameLab = CG(UILabel, root, "name")
    self.curPrice = CG(UILabel, root, "lab1/lab")
    self.origPrice = CG(UILabel, root, "lab2/lab1")
    self.discount = CG(UILabel, root, "discountSpr/lab")
    self.maxCount = CG(UILabel, root, "lab3")
    self.cellTran = Find(root, "cell", des)
    self.btn1 = FindC(root, "btn", des)
    self.btn2 = FindC(root, "btn1", des)
    self.btn3 = FindC(root, "btn2", des)

    SetB(root, "btn", des, self.OnBuy, self)
end

--更新数据
function My:Updata(cfg)
    self.cfg = cfg
    self:UpCell()
    self:UpLab()
    self:UpPriceSpr()
end

--更新道具
function My:UpCell()
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.cellTran, 0.8)
    end
    self.cell:UpData(self.cfg.id, self.cfg.num)
end

--更新文本
function My:UpLab()
    local cfg = self.cfg
    local cellCfg = ItemData[tostring(cfg.id)]
    if cellCfg == nil then return end
    self.nameLab.text = cellCfg.name
    self.origPrice.text = cfg.origPrice
    self.curPrice.text = cfg.curPrice
    self.discount.text = cfg.discount.."折"
    self:UpMaxCount()
end

--更新限购数量
function My:UpMaxCount()
    local isEnd = UIRankActiv.isEnd
    self:SetBtnState(not isEnd, false, isEnd)

    local max = self.cfg.count
    self.num = max
    for i,v in ipairs(RankActivInfo.buyList) do
        if v.id == self.cfg.index then
            self.num = self.num - v.val
            break
        end
    end
    self.maxCount.text = string.format("限购:%s/%s", self.num, max)
    if self.num == 0 and not isEnd then self:SetBtnState(false, true, false) end
end

--更新元宝贴图
function My:UpPriceSpr()
    local type = self.cfg.type
    local str = ""
    if type == 2 then
        str = "money_02"
    elseif type == 3 then
        str = "money_03"
    end
    if StrTool.IsNullOrEmpty(str) then return end
    self.spr1.spriteName = str
    self.spr2.spriteName = str
end

--点击购买
function My:OnBuy()
    if self.num == 0 then
        UITip.Log("限购数量已满")
        return
    end
    if not self:IsBuy() then
        StoreMgr.JumpRechange()
        return
    end
    local index = UIRankActiv.id
    RankActivMgr:ReqBuyItem(index, self.cfg.index)
end

--判断是否能购买
function My:IsBuy()
    local info = RoleAssets
    local type = self.cfg.type
    local price = self.cfg.curPrice
    if type == 2 then
        return info.Gold >= price
    elseif type == 3 then
        return CustomInfo:IsBuySucc(price)
    end
    return true
end

--设置按钮状态
function My:SetBtnState(state1, state2, state3)
    self.btn1:SetActive(state1)
    self.btn2:SetActive(state2)
    self.btn3:SetActive(state3)
end

--清理缓存
function My:Clear()
    self.cfg = nil
    TableTool.ClearUserData(self)
end

-- 释放资源
function My:Dispose()
    self:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return My