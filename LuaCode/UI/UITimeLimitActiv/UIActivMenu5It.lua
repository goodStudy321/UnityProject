--[[
 	authors 	:Liu
 	date    	:2019-3-20 15:00:00
 	descrition 	:限时活动界面5(奖励项)
--]]

UIActivMenu5It = Super:New{Name="UIActivMenu5It"}

local My = UIActivMenu5It

function My:Init(root, cfg)
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
    self.btn = FindC(root, "btn1", des)
    self.yes = FindC(root, "yes", des)
    self.btn2 = FindC(root, "btn2", des)

    SetB(root, "btn1", des, self.OnGet, self)
    SetB(root, "btn2", des, self.OnPay, self)

    self:InitLab(cfg)
    self:InitCell(cfg)
end

--点击领取
function My:OnGet()
    local info = TimeLimitActivInfo
    local mgr = TimeLimitActivMgr
    local type = info:GetOpenType()
    if type == 0 then return end
    mgr:ReqRankAward(type, 5, self.cfg.id)
end

--点击充值
function My:OnPay()
    VIPMgr.OpenVIP(1)
    JumpMgr:InitJump(UITimeLimitActiv.Name, 5)
end

--初始化文本
function My:InitLab(cfg)
    local info = TimeLimitActivInfo
    local recharge = info.recharge
    local limit = cfg.limit
    local val = (recharge>=limit) and limit or recharge
    local color = (recharge>=limit) and "[E5B45FFF]" or "[F21919FF]"
    self.des.text = string.format("[E16158FF]累计充值%s元宝可领取[E5B45FFF](%s%s[E5B45FFF]/%s)", limit, color, val, limit)
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
function My:UpBtnState(state)
    if state == 2 then
        self:SetBtnState(true, false, false)
        self:UpBtnName(1000)
    elseif state == 3 then
        self:SetBtnState(false, true, false)
        self:UpBtnName(8000)
    else
        self:SetBtnState(false, false, true)
        self:UpBtnName(5000)
    end
end

--更新按钮排序
function My:UpBtnName(num)
    self.go.name = self.cfg.id + num
end

--设置按钮状态
function My:SetBtnState(state1, state2, state3)
    self.btn:SetActive(state1)
    self.yes:SetActive(state2)
    self.btn2:SetActive(state3)
end

--清理缓存
function My:Clear()
    TableTool.ClearListToPool(self.cellList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My