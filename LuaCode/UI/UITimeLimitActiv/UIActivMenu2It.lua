--[[
 	authors 	:Liu
 	date    	:2019-3-20 15:00:00
 	descrition 	:限时活动界面2(奖励项)
--]]

UIActivMenu2It = Super:New{Name="UIActivMenu2It"}

local My = UIActivMenu2It

function My:Init(root, cfg, fStr)
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
    self.no = FindC(root, "no", des)

    SetB(root, "btn1", des, self.OnGet, self)

    self:InitLab(cfg, fStr)
    self:InitCell(cfg)
end

--点击领取
function My:OnGet()
    local info = TimeLimitActivInfo
    local mgr = TimeLimitActivMgr
    local type = info:GetOpenType()
    if type == 0 then return end
    mgr:ReqRankAward(type, 2, self.cfg.id)
end

--初始化文本
function My:InitLab(cfg, fStr)
    local num = tonumber(fStr)
    local val = (num>=cfg.cond) and cfg.cond or fStr
    local color = (num>=cfg.cond) and "[E5B45FFF]" or "[F21919FF]"
    self.des.text = string.format("[E16158FF]战力达到%s可领取[E5B45FFF](%s%s[E5B45FFF]/%s)", cfg.cond, color, val, cfg.cond)
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
    self.no:SetActive(state3)
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