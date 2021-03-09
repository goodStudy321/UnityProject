--[[
 	authors 	:Liu
 	date    	:2019-3-22 10:10:00
 	descrition 	:七日投资项
--]]

UISevenInvestIt = Super:New{Name="UISevenInvestIt"}

local My = UISevenInvestIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg

    self.spr = CG(UISprite, root, "spr1")
    self.count = CG(UILabel, root, "lab1")
    self.tran = Find(root, "cell", des)
    self.btn = FindC(root, "btn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)

    SetB(root, "btn", des, self.OnGet, self)

    self:InitSpr(cfg)
    self:InitCount(cfg)
    self:InitCell(cfg)
end

--点击领取
function My:OnGet()
    TimeLimitActivMgr:ReqSevenAward(self.cfg.id)
end

--初始化天数图片
function My:InitSpr(cfg)
    self.spr.spriteName = "d"..cfg.id
end

--初始化数量
function My:InitCount(cfg)
    self.count.text = cfg.award[1].v
end

--初始化道具
function My:InitCell(cfg)
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(self.tran, 0.9)
    self.cell:UpData(cfg.award[1].k)
end

--更新按钮状态
function My:UpBtnState(state)
    if state == 2 then
        self:SetBtnState(true, false, false)
    elseif state == 3 then
        self:SetBtnState(false, true, false)
    else
        self:SetBtnState(false, false, true)
    end
end

--设置按钮状态
function My:SetBtnState(state1, state2, state3)
    self.btn:SetActive(state1)
    self.yes:SetActive(state2)
    self.no:SetActive(state3)
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