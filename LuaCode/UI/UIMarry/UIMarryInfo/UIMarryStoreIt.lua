--[[
 	authors 	:Liu
 	date    	:2018-12-10 16:00:00
 	descrition 	:结婚商城物品项
--]]

UIMarryStoreIt = Super:New{Name = "UIMarryStoreIt"}

local My = UIMarryStoreIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetS = UITool.SetBtnSelf
    local SetB = UITool.SetBtnClick

    self.tex = CG(UITexture, root, "icon")
    self.nameLab = CG(UILabel, root, "lab")
    self.coinLab = CG(UILabel, root, "priceBg/coinLab")
    self.count = CG(UILabel, root, "CountBg/coinLab")
    self.coinBg = CG(UISprite, root, "priceBg/coinBg")
    self.input = CG(UIInput, root, "CountBg")
    self.cfg = cfg
    self.num = 1

    local ED = EventDelegate
    ED.Add(self.input.onChange, ED.Callback(self.OnInputChange, self))

    SetS(root, self.OnClick, self, des)
    SetB(root, "CountBg/plus", des, self.OnPlus, self)
    SetB(root, "CountBg/lower", des, self.OnLower, self)
    SetB(root, "buyBtn", des, self.OnBuy, self)

    self:InitLab()
    self:InitSpr()
    self:InitCountLab()
    self:InitTex()
end

--输入状态改变
function My:OnInputChange()
    local val = tonumber(self.input.value)
    if val then
        if val > 99 then
            self.input.value = 99
        elseif val < 2 then
            self.input.value = 1
        end
        self.num = tonumber(self.input.value)
        self:UpBuyShow()
    end
end

--初始化图片
function My:InitTex()
    local key = self.cfg.PropId
    local cfg = ItemData[key]
    if cfg == nil then return end
    self.texName = cfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置图片
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--初始化数量文本
function My:InitCountLab()
    self.count.text = self.num
    self:UpBuyShow()
end

--初始化元宝样式
function My:InitSpr()
    local cfg = self.cfg
    if cfg.priceTp == 2 then
        self.coinBg.spriteName = "money_02"
    elseif cfg.priceTp == 4 then
        self.coinBg.spriteName = "money_03"
    end
end

--初始化文本
function My:InitLab()
    local cfg = self.cfg
    self.nameLab.text = cfg.name
    self.coinLab.text = cfg.curPrice
end

--点击增加数量
function My:OnPlus()
    if self.num >= 99 then return end
    self.num = self.num + 1
    self.count.text = self.num
    self:UpBuyShow()
end

--点击减少数量
function My:OnLower()
    if self.num < 2 then return end
    self.num = self.num - 1
    self.count.text = self.num
    self:UpBuyShow()
end

--更新购买商品的显示
function My:UpBuyShow()
    local cfg = self.cfg
    self.coinLab.text = cfg.curPrice * self.num
end

--点击购买
function My:OnBuy()
    local info = RoleAssets
    local cfg = self.cfg
    if cfg.priceTp == 2 then
        if info.Gold < cfg.curPrice then
            UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
            return
        end
    else
        if CustomInfo:IsBuySucc(cfg.curPrice)==false then
            UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
            return
        end
    end
    StoreMgr.ReqBugGoods(self.cfg.id, self.num)
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel("元宝不足，是否充值？")
    end
end

--点击自身
function My:OnClick()
    UIMarryInfo.storeMenu:UpDesLab(self.cfg)
end

--清理缓存
function My:Clear()
    self.cfg = nil
    self.num = 1
    AssetMgr:Unload(self.texName,false)
    self.texName = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    local ED = EventDelegate
	ED.Remove(self.input.onChange, ED.Callback(self.OnInputChange, self))
end
    
return My