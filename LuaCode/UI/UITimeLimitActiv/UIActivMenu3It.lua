--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面3(奖励项)
--]]

UIActivMenu3It = Super:New{Name="UIActivMenu3It"}

local My = UIActivMenu3It

function My:Init(root, cfg, bStr)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
	
    self.cfg = cfg
    self.cellList = {}
    self.go = root.gameObject

    self.grid = Find(root, "Grid", des)
    self.des = CG(UILabel, root, "des")
    self.count = CG(UILabel, root, "count")
    self.discount = CG(UILabel, root, "spr/lab")
    self.spr1 = CG(UISprite, root, "price1/spr1")
    self.spr2 = CG(UISprite, root, "price2/spr1")
    self.price1 = CG(UILabel, root, "price1/lab1")
    self.price2 = CG(UILabel, root, "price2/lab1")
    self.btn = FindC(root, "btn1", des)

    SetB(root, "btn1", des, self.OnBuy, self)

    self:InitLab(cfg, bStr)
    self:InitSpr(cfg)
    self:InitCell(cfg)
end

--点击购买
function My:OnBuy()
    local cfg = self.cfg
    if cfg.goldType == 2 then
        if RoleAssets.Gold < cfg.cPrice then
            StoreMgr.JumpRechange()
            JumpMgr:InitJump(UITimeLimitActiv.Name, 3)
            return
        end
    elseif cfg.goldType == 3 then
        if RoleAssets.BindGold < cfg.cPrice then
            UITip.Log("绑定元宝不足")
            return
        end
    end
    local info = TimeLimitActivInfo
    local mgr = TimeLimitActivMgr
    local type = info:GetOpenType()
    if type == 0 then return end
    mgr:ReqRankAward(type, 4, self.cfg.id)
end

--初始化文本
function My:InitLab(cfg, bStr)
    self.des.text = string.format("超值%s礼包", bStr)
    self.discount.text = cfg.discount.."折"
    self.price1.text = cfg.oPrice
    self.price2.text = cfg.cPrice
end

--初始化元宝图片
function My:InitSpr(cfg)
    local str = (cfg.goldType==2) and "money_02" or "money_03"
    self.spr1.spriteName = str
    self.spr2.spriteName = str
end

--初始化道具
function My:InitCell(cfg)
    for i,v in ipairs(cfg.rankAward) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.8)
        cell:UpData(v.I, v.B, v.N==2)
        table.insert(self.cellList, cell)
    end
end

--更新按钮
function My:UpBtnState(count)
    local cfg = self.cfg
    local num = (count) and cfg.buyCount - count or cfg.buyCount
    local color = (num<1) and "[F21919FF]" or "[00FF00FF]"
    self.count.text = string.format("[99886BFF]限购次数:%s%s[00FF00FF]/%s", color, num, cfg.buyCount)
    if num > 0 then
        UITool.SetNormal(self.btn)
        self:UpBtnName(1000)
    else
        UITool.SetGray(self.btn)
        self:UpBtnName(5000)
    end
end

--更新按钮排序
function My:UpBtnName(num)
    self.go.name = self.cfg.id + num
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    TableTool.ClearListToPool(self.cellList)
    self:Clear()
end

return My