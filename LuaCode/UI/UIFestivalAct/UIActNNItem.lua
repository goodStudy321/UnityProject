--[[
 	authors 	:Liu
 	date    	:2019-2-14 15:00:00
 	descrition 	:你侬我侬奖励项
--]]

UIActNNItem = Super:New{Name = "UIActNNItem"}

local My = UIActNNItem

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.cellList = {}
    self.go = root.gameObject
    self.lab = CG(UILabel, root, "Des")
    self.btn = FindC(root, "Btn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)
    self.grid = Find(root, "Grid", des)

    SetB(root, "Btn", des, self.OnBtn, self)

    self:ChangeName()
    self:InitCell()
    self:InitDesLab()
    self:UpBtnState()
end

--点击领取
function My:OnBtn()
    local mgr = FestivalActMgr
    mgr:ReqBgActReward(self.cfg.type, self.cfg.id)
end

--设置按钮状态
function My:SetBtnState()
    self:ChangeName()
    self:UpBtnState()
    FestivalActMgr:UpdateRedPoint(1001)
end

--显示按钮状态
function My:UpBtnState()
    local cfg = self.cfg
    if cfg.state == 1 then
        self:ShowBtnState(true, false, false)
    elseif cfg.state == 2 then
        self:ShowBtnState(false, true, false)
    elseif cfg.state == 3 then
        self:ShowBtnState(false, false, true)
    end
end

--更新按钮状态
function My:ShowBtnState(state1, state2, state3)
    self.no:SetActive(state1)
    self.btn:SetActive(state2)
    self.yes:SetActive(state3)
end

--更新道具
function My:InitCell()
    local cfg = self.cfg
    for i,v in ipairs(cfg.rewardList) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.8)
        cell:UpData(v.id, v.num, v.effNum==1)
        table.insert(self.cellList, cell)
    end
end

--初始化描述文本
function My:InitDesLab()
    self.lab.text = self.cfg.des.."："
end

--改变名字
function My:ChangeName()
    local num = 0
    local cfg = self.cfg
    if cfg.state == 1 then
        num = cfg.id + 5000
    elseif cfg.state == 2 then
        num = cfg.id + 1000
    elseif cfg.state == 3 then
        num = cfg.id + 8000
    end
    self.go.name = num
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My