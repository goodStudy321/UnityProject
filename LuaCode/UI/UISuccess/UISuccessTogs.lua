--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面Table下的Togs
--]]

UISuccessTogs = Super:New{Name = "UISuccessTogs"}

local My = UISuccessTogs

local Info = require("Success/SuccessInfo")
require("UI/UISuccess/UISuccessTogsGrid")

function My:Init(root, cfg)
    local des, FindC = self.Name, TransTool.FindChild
    local CG, Find = ComTool.Get, TransTool.Find
    grid = Find(root, "Tween/Grid", des)
    UITool.SetLsnrSelf(root, self.OnTog, self, des)

    self.tog = ComTool.GetSelf(UIToggle, root, des)
    self.up = FindC(root, "up", des)
    self.down = FindC(root, "down", des)
    self.action = FindC(root, "Action", des)
    self.cfg = cfg
    self.labList = {}

    self:InitLab(root, CG, cfg)
    self:InitTog(cfg)
    self:InitModule(grid, cfg)
    -- self:UpAction()
end

--点击Tog
function My:OnTog(go)
    local id = self.cfg.id
    local index = Info.togIndex
    local succ = UISuccess
    local list = succ.tab.itList
    if index == 0 then return end
    list[index]:UpLab(index, false)
    list[id]:UpLab(id, true)

    if go.name == "tog1" then
        self:UpModData(id)
        self:SetModState(true)
    else
        self:SetTogState(index, id, list)
        self:SetModState(false)
    end
    Info.togIndex = id
end

--设置模块状态
function My:SetModState(state)
    local succ = UISuccess
    succ.mod1.go:SetActive(state)
    succ.mod2.go:SetActive(state)
    succ.mod3.go:SetActive(not state)
end

--更新模块数据
function My:UpModData(id)
    local succ = UISuccess
    local num = SuccessInfo.tabIndex
    if id == 1 then
        succ.mod1:UpData()
        succ.mod2:UpData(101)
    else
        succ.mod3:UpData(num)
    end
end

--设置Tog状态
function My:SetTogState(index, id, list)
    local state = self.up.activeSelf
    self:UpTogState(not state)
    self.grid:UpShow(state)
    self:UpModData(id)
end

--初始化Tog
function My:InitTog(cfg)
    local id = cfg.id
    if id == 1 then
        self.tog.value = true
        self:UpLab(id, true)
        Info.togIndex = id
        self:SetModState(true)
        self:UpModData(id)
    else
        self:UpTogState(true)
    end
end

--更新Tog状态
function My:UpTogState(state)
    self.up:SetActive(state)
    self.down:SetActive(not state)
end

--初始化文本
function My:InitLab(root, CG, cfg)
    for i=1, 4 do
        local lab = CG(UILabel, root, "lab"..i)
        table.insert(self.labList, lab)
        if cfg.id == 1 and i == 3 then  
            lab.gameObject:SetActive(true)
        elseif cfg.id ~= 1 and i == 1 then
            lab.gameObject:SetActive(true)
        end
        lab.text = cfg.pType
    end
end

--更新文本
function My:UpLab(idnex, state)
    local num = (idnex==1) and 4 or 2
    self.labList[num].gameObject:SetActive(state)
end

--初始化红点状态
function My:UpAction(list)
    for i,v in ipairs(list) do
        if v == self.cfg.id then
            self:UpActionGo(true)
            return
        end
    end
    self:UpActionGo(false)
end

--更新红点状态
function My:UpActionGo(state)
    self.action:SetActive(state)
end

--初始化模块
function My:InitModule(grid, cfg)
    self.grid = ObjPool.Get(UISuccessTogsGrid)
    self.grid:Init(grid, cfg)
end

--清理缓存
function My:Clear()
    self.tog = nil
    self.up = nil
    self.down = nil
    self.cfg = nil
end

-- 释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearDic(self.labList)
end

return My