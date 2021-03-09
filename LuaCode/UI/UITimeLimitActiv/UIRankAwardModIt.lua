--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面1(奖励项)
--]]

UIRankAwardModIt = Super:New{Name="UIRankAwardModIt"}

local My = UIRankAwardModIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.cellList = {}

    self.grid = Find(root, "Grid", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab1/lab2")
    self.btn = FindC(root, "getBtn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)

    SetB(root, "getBtn", des, self.OnGet, self)

    self:InitLab(cfg)
    self:InitCell(cfg)
end

--点击领取
function My:OnGet()
    local info = TimeLimitActivInfo
    local mgr = TimeLimitActivMgr
    local type = info:GetOpenType()
    if type == 0 then return end
    mgr:ReqRankAward(type, 1, self.cfg.id)
end

--初始化文本
function My:InitLab(cfg)
    local temp1 = 0
    local temp2 = 0
    local str1 = ""
    local str2 = ""
    local condStr = {"充值"}
    local valStr = {"元宝"}
    for i,v in ipairs(cfg.rank) do
        if i==1 then temp1 = v else temp2 = v end
    end
    local rankStr = (temp1==temp2) and temp1 or temp1.."-"..temp2
    local typeStr = self:GetTypeStr()

    self.lab1.text = string.format("%s总战力第%s名", typeStr, rankStr)
    self.lab2.text = string.format("且%s%s%s可领取", condStr[cfg.cond], cfg.condVal, valStr[cfg.cond])
end

--获取类型文本
function My:GetTypeStr()
    local str = ""
    local info = TimeLimitActivInfo
    local type = info:GetOpenType()
    local idList = info.idList
    if type == idList[1] then
		str = "法宝"
	elseif type == idList[2] then
		str = "翅膀"
	elseif type == idList[3] then
		str = "图鉴"
    end
    return str
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
    TableTool.ClearListToPool(self.cellList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My