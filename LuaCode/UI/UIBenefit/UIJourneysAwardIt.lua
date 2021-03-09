--[[
 	authors 	:Liu
 	date    	:2019-04-17 16:20:00
 	descrition 	:任务奖励项
--]]

UIJourneysAwardIt = Super:New{Name = "UIJourneysAwardIt"}

local My = UIJourneysAwardIt

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

    self:ChangeName(cfg.id)
    self:InitCell()
    self:InitDesLab()
end

--点击领取
function My:OnBtn()
    JourneysMgr:ReqGetAward(self.cfg.id)
end

--更新按钮状态
function My:UpBtnState(state)
    if state == 2 then
        self:ChangeName(1000)
        self:SetBtnState(true, false, false)
    elseif state == 3 then
        self:ChangeName(5000)
        self:SetBtnState(false, true, false)
    else
        self:ChangeName(3000)
        self:SetBtnState(false, false, true)
    end
end

--设置按钮状态
function My:SetBtnState(state1, state2, state3)
    self.btn:SetActive(state1)
    self.yes:SetActive(state2)
    self.no:SetActive(state3)
end

--更新道具
function My:InitCell()
    local cfg = self.cfg
    for i,v in ipairs(cfg.award) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.8)
        cell:UpData(v.k, v.v)
        table.insert(self.cellList, cell)
    end
end

--初始化描述文本
function My:InitDesLab()
    local mana = JourneysMgr.mana
    local count = self.cfg.id
    local val = (mana >= count) and count or mana 
	local str = string.format("%s/%s仙力值可领取", val, count)
    self.lab.text = str
end

--改变名字
function My:ChangeName(num)
	self.go.name = self.cfg.id + num
end

--清理缓存
function My:Clear()
    
end

-- 释放资源
function My:Dispose()
	self:Clear()
	TableTool.ClearListToPool(self.cellList)
end

return My