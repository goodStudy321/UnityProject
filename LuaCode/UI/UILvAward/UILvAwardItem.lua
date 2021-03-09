--[[
 	authors 	:Liu
 	date    	:2018-5-22 10:09:28
 	descrition 	:等级奖励项
--]]

UILvAwardItem = Super:New{Name="UILvAwardItem"}

local My = UILvAwardItem

require("UI/UILvAward/UIGiftItem")

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local str = "GetBtn"
    self.root = root
    self.cfg = cfg
    self.go = root.gameObject
    self.itList = {}
    self.lvLab = CG(UILabel, root, "TitleLab")
    self.getLab = CG(UILabel, root, str.."/GetLab")
    self.countLab = CG(UILabel, root, str.."/Label")
    self.getSpr = CG(UISprite, root, str)
    self.getBtn = CG(UIButton, root, str)
    self:InitSelf(cfg)
    self:InitAwardItem(cfg, root, des)
end

--点击领取按钮
function My:OnGetBtnClick()
    local getLevel = self.cfg.id
    if User.MapData.Level >= getLevel then
        LvAwardMgr:ReqGetLvAward(getLevel)
    end
end

--初始化自身
function My:InitSelf(cfg)
    local count = LvAwardInfo:GetWordAward(cfg)
    local val = (cfg.count == 0) and "不限数量" or "剩余："..count.."件"
    self.lvLab.text = "·等级达到"..cfg.id.."级"
    self.countLab.text = val
end

--初始化奖励物品
function My:InitAwardItem(cfg, root, des)
    local Find = TransTool.Find
    local list = self.itList
    for i,v in ipairs(cfg.award) do
        local tran = Find(root, "Item"..i, des)
        local it = ObjPool.Get(UIGiftItem)
        it:Init(tran, v)
        list[#list+1] = it
    end
end

--未领取状态
function My:NoGet()
    self:SetBtnState(false, "[5d5451]领取")
end

--可领取状态
function My:MayGet()
    self:SetBtnState(true, "[772A2AFF]领取")
    UITool.SetBtnClick(self.root, "GetBtn", self.Name, self.OnGetBtnClick, self)
end

--已领取状态
function My:YetGet()
    self:SetBtnState(false, "[5d5451]已领取")
    self.go.name = 300 + self.cfg.id
end

--设置按钮状态
function My:SetBtnState(state, str)
    self.getBtn.enabled = state
    self:UpBtnIcon(state)
    self.getLab.text = str
end

--更改按钮精灵
function My:UpBtnIcon(isActive)
    local spr = self.getSpr
    spr.spriteName = (isActive) and "btn_figure_non_avtivity" or "btn_figure_down_avtivity"
end

--更新限制奖励文本
function My:UpCountLab()
    local count = LvAwardInfo:GetWordAward(self.cfg)
    self.countLab.text = "剩余："..count.."件"
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    ListTool.ClearToPool(self.itList)
end

return My