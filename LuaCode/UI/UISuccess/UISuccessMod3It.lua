--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:模块3成就项
--]]

UISuccessMod3It = Super:New{Name = "UISuccessMod3It"}

local My = UISuccessMod3It

function My:Init(root)
    local des, CG = self.Name, ComTool.Get
    local FinC = TransTool.FindChild
    
    self.item = FinC(root, "Grid/item", des)
    self.item:SetActive(false)
    self.getBtn = FinC(root, "getBtn", des)
    self.yesSpr = FinC(root, "yes", des)
    self.noSpr = FinC(root, "no", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.lab3 = CG(UILabel, root, "spr3/lab")
    self.grid = CG(UIGrid, root, "Grid")
    self.go = root.gameObject
    self.cellList = {}
    UITool.SetLsnrSelf(self.getBtn.transform, self.OnGetClick, self, des)
end

--点击领取按钮
function My:OnGetClick()
    SuccessMgr:ReqSuccAward(self.cfg.id)
end

--更新数据
function My:UpData(cfg)
    self.cfg = cfg
    self:BtnSort()
    self:UpLab()
    self:UpCell()
    self:UpBtnStae()
end

--成就项排序
function My:BtnSort()
    local go = self.go
    local cfg = self.cfg
    local key = tostring(cfg.id)
    local cond = cfg.condition
    local info = SuccessInfo
    local isGet, count = info:IsGet(key)
    if info.getDic[key] then
        go.name = cfg.id + 2000
    elseif count >= cond and isGet then
        go.name = cfg.id
    else
        go.name = cfg.id + 1000
    end
end

--更新按钮状态
function My:UpBtnStae()
    local cfg = self.cfg
    local info = SuccessInfo
    local key = tostring(cfg.id)
    local cond = cfg.condition
    local isGet, count = info:IsGet(key)
    
    if count >= cond and not info.getDic[key] then--未领取
        if isGet then
            self:SetBtnState(true, false, false)
        else
            self:SetBtnState(false, false, true)
            iTrace.Error("SJ", "前后端的条件ID不一致")
        end
    elseif count >= cond and info.getDic[key] then--已领取
        self:SetBtnState(false, true, false)
    elseif count < cond then--不能领取
        self:SetBtnState(false, false, true)
    end
end

--设置按钮状态
function My:SetBtnState(state1, state2, state3)
    self.getBtn:SetActive(state1)
    self.yesSpr:SetActive(state2)
    self.noSpr:SetActive(state3)
end

--更新文本
function My:UpLab(cfg)
    local cfg = self.cfg
    local cond = cfg.condition
    local key = tostring(cfg.id)
    local isGet, count = SuccessInfo:IsGet(key)
    local str = (count >= cond) and "[99886b]%s（[66c34e]%s / %s[-]）" or "[99886b]%s（[f21919]%s [66c34e]/ %s[99886b]）"
    count = (count >= cond) and cond or count
    count = math.NumToStrCtr(count)
    cond = math.NumToStrCtr(cond)
    str = string.format(str, cfg.des, count, cond)
    self.lab1.text = cfg.name
    self.lab2.text = str
    self.lab3.text = cfg.score
end

--更新Cell
function My:UpCell()
    local item = self.item
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    local list = self.cellList
    local award = self.cfg.award

    if #list < #award then
		local num = #award - #list
		for i=1, num do
            local go = Instantiate(item)
            local tran = go.transform
            Add(parent, tran)
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(tran, 0.75)
            table.insert(self.cellList, cell)
		end
		self:UpCellData(award)
	else
		self:UpCellData(award)
    end
    self.grid:Reposition()
end

--更新Cell数据
function My:UpCellData(award)
    for i,v in ipairs(self.cellList) do
        if i > #award then
            self:SetCellState(v, false)
        else
            v:UpData(award[i].k, award[i].v)
            self:SetCellState(v, true)
        end
    end
end

--设置Cell状态
function My:SetCellState(it, state)
    it.trans.parent.gameObject:SetActive(state)
end

--显示成就项
function My:Show()
    self.go:SetActive(true)
end

--隐藏成就项
function My:Hide()
    self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

-- 释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My