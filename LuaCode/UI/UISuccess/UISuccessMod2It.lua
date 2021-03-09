--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:模块2的成就项
--]]

UISuccessMod2It = Super:New{Name = "UISuccessMod2It"}

local My = UISuccessMod2It

function My:Init(root, cfg, isTop)
    local des, CG = self.Name, ComTool.Get
    local FinC = TransTool.FindChild

    self.cfg = cfg
    self.isTop = isTop
    self.go = root.gameObject
    self.getBtn = FinC(root, "getBtn", des)
    self.yesSpr = FinC(root, "yes", des)
    self.noSpr = FinC(root, "no", des)
    self.item = FinC(root, "Grid/item", des)
    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.cellList = {}
    UITool.SetLsnrSelf(self.getBtn.transform, self.OnGetClick, self, des)
end

--点击领取按钮
function My:OnGetClick()
    SuccessMgr:ReqSuccAward(self.cfg.id)
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

--更新数据
function My:UpData(cfg)
    self:BtnSort()
    self:UpLab()
    self:InitCell(cfg)
end

--成就项排序
function My:BtnSort()
    local go = self.go
    local cfg = self.cfg
    local key = tostring(cfg.id)
    if self.isTop then
        go.name = 1
        return
    end
    if SuccessInfo.getDic[key] then
        go.name = cfg.id + 1000
    else
        go.name = cfg.id
    end
end

--更新文本
function My:UpLab()
    local cfg = self.cfg
    local cond = cfg.condition
    local key = tostring(cfg.id)
    local isGet, count = SuccessInfo:IsGet(key)
    local str = (count >= cond) and "[99886b]%s（[66c34e]%s / %s[-]）" or "[99886b]%s（[f21919]%s [66c34e]/ %s[99886b]）"
    count = (count >= cond) and cond or count
    str = string.format(str, cfg.des, count, cond)
    self.lab1.text = cfg.name
    self.lab2.text = str
end

--初始化Cell
function My:InitCell(cfg)
    local item = self.item
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(cfg.award) do
        local go = Instantiate(item)
        local tran = go.transform
        Add(parent, tran)
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(tran, 0.75)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
    item:SetActive(false)
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