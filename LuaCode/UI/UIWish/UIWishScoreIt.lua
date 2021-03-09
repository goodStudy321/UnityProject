--[[
 	authors 	:Liu
 	date    	:2019-1-14 14:00:00
 	descrition 	:许愿积分项
--]]

UIWishScoreIt = Super:New{Name = "UIWishScoreIt"}

local My = UIWishScoreIt

function My:Init(root, cfg, isOpen)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.isOpen = isOpen
    self.cfg = cfg
    self.cellList = {}
    self.root = root
    self.go = root.gameObject
    self.lab = CG(UILabel, root, "lab1")
    self.getBtn = FindC(root, "getBtn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)

    SetB(root, "getBtn", des, self.OnGet, self)

    self:InitCell(root, cfg, des)
    self:InitLab()
    self:UpBtnState()

    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = FestivalActMgr
    local mgr1 = TimeLimitActivMgr
    mgr.eUpdateActItemList[func](mgr.eUpdateActItemList, self.RespUpdateActItemList, self)
    mgr1.eUpWishAward[func](mgr1.eUpWishAward, self.RespUpWishAward, self)
end

--响应更新积分奖励兑换
function My:RespUpdateActItemList()
    self:UpBtnState()
    UIWish:UpAction()
    UIWish.panel2:Reposition()
    FestivalActMgr:UpWishAction()
end

--响应积分奖励
function My:RespUpWishAward(id, val)
    if id == self.cfg.id then
        self.state = val
        self:UpBtnState()
        UIWish:UpAction()
    end
    UIWish.panel2:Reposition()
end

--点击领取
function My:OnGet()
    if self.isOpen then
        TimeLimitActivMgr:ReqWishAward(self.cfg.id)
    else
        local mgr = FestivalActMgr
        mgr:ReqBgActReward(self.cfg.type, self.cfg.id)
    end
end

--设置按钮状态
function My:SetBtnState()
    local infoList = FestivalActInfo.wishData.updateList
    for i,v in ipairs(infoList) do
        if v.id == self.cfg.id then
            self.cfg.state = v.state
            self:UpBtnState()
        end
    end
end

--更新按钮状态
function My:UpBtnState()
    local cfg = self.cfg
    local state = (self.isOpen) and self.state or cfg.state
    if state == 2 then
        self:ShowBtnState(false, true, false)
    elseif state == 3 then
        self:ShowBtnState(false, false, true)
    else
        self:ShowBtnState(true, false, false)
    end
    self:ChangeName(state)
end

--设置按钮状态
function My:ShowBtnState(state1, state2, state3)
    self.no:SetActive(state1)
    self.getBtn:SetActive(state2)
    self.yes:SetActive(state3)
end

--初始化奖励项
function My:InitCell(root, cfg, des)
    local Find = TransTool.Find
    if self.isOpen then
        for i,v in ipairs(cfg.award) do
            if i > 5 then return end
            local tran = Find(root, "Grid/item"..i, des)
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(tran, 0.8)
            cell:UpData(v.k, v.v)
            table.insert(self.cellList, cell)
        end
    else
        for i,v in ipairs(cfg.rewardList) do
            if i > 5 then return end
            local tran = Find(root, "Grid/item"..i, des)
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(tran, 0.8)
            cell:UpData(v.id, v.num, v.effNum==1)
            table.insert(self.cellList, cell)
        end
    end
end

--初始化文本
function My:InitLab()
    if self.isOpen then
        self.lab.text = string.format("[F4DDBDFF]好运积分达到[F39800FF]%s分[-]即可领取", self.cfg.score)
    else
        self.lab.text = self.cfg.des
    end
end

--改变名字
function My:ChangeName(state)
    local num = 0
    local cfg = self.cfg
    if state == 1 then
        num = cfg.id + 5000
    elseif state == 2 then
        num = cfg.id + 1000
    elseif state == 3 then
        num = cfg.id + 8000
    end
    self.go.name = num
end

--初始化状态
function My:UpState(state)
    self.state = state
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
    self:SetLnsr("Remove")
end
    
return My