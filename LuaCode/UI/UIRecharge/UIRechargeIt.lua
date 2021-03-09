--[[
 	authors 	:Liu
 	date    	:2018-8-17 12:00:00
 	descrition 	:充值项
--]]

UIRechargeIt = Super:New{Name="UIRechargeIt"}

local My = UIRechargeIt

function My:Init(root, cfg)
    local CG, des = ComTool.Get, self.Name
    local Find = TransTool.Find
    local priceTran = Find(root, "spr2", des)
    local moneyLab = CG(UILabel, root, "lab")
    local getLab = CG(UILabel, root, "getSpr/lab")
    local icon = CG(UISprite, root, "icon")
    self.giveLab = CG(UILabel, root, "giveSpr/lab1")
    self.cfg = cfg
    UITool.SetBtnSelf(root, self.OnClick, self, des)
    self:InitLab(cfg, moneyLab, getLab)
    self:InitPricePos(cfg, priceTran, moneyLab)
    self:InitIcon(icon, cfg)
    self:InitEffect(icon.transform,cfg)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    RechargeMgr.eRechargeInfo[func](RechargeMgr.eRechargeInfo, self.RespRechargeInfo, self)
end

--响应充值信息
function My:RespRechargeInfo()
    self:UpRechargeState()
end

--初始化文本
function My:InitLab(cfg, moneyLab, getLab)
    if cfg == nil then iTrace.Error("SJ", "充值配置不存在") return end
    moneyLab.text = cfg.gold
    getLab.text = cfg.getGold
    self:UpRechargeState()
end

--初始化Icon
function My:InitIcon(icon, cfg)
    if cfg.id == 3 or cfg.id == 6 then
        icon.width = 190
        icon.height = 190
    end
    icon.spriteName = cfg.icon
end

--初始化特效
function My:InitEffect(root,cfg)
    local effectName = cfg.effectName;
    local effect = UIRecharge.GetEffect(effectName);
    effect.transform.parent = root;
    effect.transform.localPosition = Vector3.New(0,0,-1);
    effect.transform.localScale = Vector3.one;
    effect:SetActive(true);
    self.effect = effect;
end

--初始化价格文本位置
function My:InitPricePos(cfg, priceTran, moneyLab)
    local x = 0
    if cfg.gold < 10 then
        x = 0
    elseif cfg.gold < 100 then
        x = -10
    elseif cfg.gold < 1000 then
        x = -20
    elseif cfg.gold < 10000 then
        x = -30
    elseif cfg.gold < 100000 then
        x = -40
    end
    priceTran.localPosition = Vector3(x, priceTran.localPosition.y, 0)
    moneyLab.transform.localPosition = Vector3(x+10, moneyLab.transform.localPosition.y, 0)
end

--更新充值状态
function My:UpRechargeState()
    local mgr = RechargeMgr
    local giveLab = self.giveLab
    local cfg = self.cfg
    local key = tostring(cfg.id)
    if mgr.firstDic[key] then
        local parent = giveLab.transform.parent
        parent.gameObject:SetActive(false)
    else
        giveLab.text = cfg.bidGold1
    end
end

--点击充值项
function My:OnClick()
    RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
end

--编辑器
function My:Func1()
    
end

--Android
function My:Func2()
    RechargeMgr:ReqRecharge(self.cfg.id)
end

--IOS
function My:Func3()
    RechargeMgr:ReqRecharge(self.cfg.id)
end

--其他
function My:Func4()
    
end

--清理特效
function My:ClearEffect()
    local isNull = LuaTool.IsNull(self.effect);
    if isNull == false then
        Destroy(self.effect);
    end
    self.effect = nil;
end

--清理缓存
function My:Clear()
    self.cfg = nil
    self.giveLab = nil
    self:ClearEffect();
end
        
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
end

return My