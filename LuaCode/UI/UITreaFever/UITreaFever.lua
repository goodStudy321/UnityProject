--[[
    神秘宝藏
]]

UITreaFever = UIBase:New{Name = "UITreaFever"}

local M = UITreaFever

local US = UITool.SetBtnClick
local USS = UITool.SetLsnrSelf
local T = TransTool.FindChild
local C = ComTool.Get
local CS = ComTool.GetSelf
local Add = TransTool.AddChild

require("UI/UITreaFever/FeverCopy")
require("UI/UITreaFever/FeverStore")
require("UI/UITreaFever/TreaFever")

function M:InitCustom()
    local des = self.Name
    local root = self.root

    self.Grid = C(UIGrid,root,"ActivModule/grid",des)
    self.modDic = {}
    self.togDic = {}
    self.actionDic = {}
    self.strDic = {}
    self.modInfoDic = {}
    self.curIndex = 0
    
    self.strDic["1"] = "宝藏秘境"
    local module1 = T(root, "copyModule", des)
    self:SetModInfo(module1, FeverCopy, 1)

    self.strDic["2"] = "神秘宝藏"
    local module2 = T(root, "feverModule", des)
    self:SetModInfo(module2, TreaFever,2)

   
    self.strDic["3"] = "宝藏商城"
    local module3 = T(root, "storeModule", des)
    self:SetModInfo(module3, FeverStore, 3)

    
    self.tog = T(root, "ActivModule/grid/tog1", des)

    US(root, "CloseBtn", des, self.Close, self)

    self:SetLnsr("Add")

    local index = (self.index==nil) and 1 or self.index
    if self.index == nil then self:OpenTab(index) end
end

--设置监听
function M:SetLnsr(fun)
    TreaFeverMgr.eRed[fun](TreaFeverMgr.eRed,self.UpAction,self)
end

--更新红点
function M:UpAction(red)
    self.actionDic["2"]:SetActive(TreaFeverMgr.FindRed)
end

--初始化Togs
function M:InitTogs()
    if self.tog == nil then self:Close() return end
    local parent = self.tog.transform.parent
    for k,v in pairs(self.strDic) do
        local go = Instantiate(self.tog)
        local tran = go.transform
        go.name = k
        local red = T(tran, "Action", self.Name)
        local lab1 = C(UILabel, tran, "Label")
        local lab2 = C(UILabel, tran, "Label1")
        local tog = CS(UIToggle, tran, self.Name)
        lab1.text = v
        lab2.text = v
        Add(parent, tran)
        USS(tran, self.OnTog, self, self.Name)
        self.actionDic[k] = red
        self.togDic[k] = tog
    end
    local index = self.index
	local num = (index and self.togDic[index]) and index or "1"
	self.togDic[num].value = true
    self:SwitchMenu(num)
    self.tog:SetActive(false)
    self.Grid:Reposition()
end

--点击Tog
function M:OnTog(go)
    self:SwitchMenu(go.name)
    --My.eSwitch()
end

--设置界面状态
function M:SwitchMenu(key)
    if self.curIndex == key then return end
    local k = tostring(key)
    if self.modDic[k] == nil then
        local info = self.modInfoDic[k]
        if info == nil then return end
        self:InitModule(info.tran, info.obj, info.key)
    end
    for k,v in pairs(self.modDic) do
        if k == key then
            v:UpShow(true)
        else
            v:UpShow(false)
        end
    end
    self.curIndex = key
end

--初始化模块
function M:InitModule(module, class, index)
    local key = tostring(index)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    self.modDic[key] = mod
end

--设置模块信息
function M:SetModInfo(tran, obj, key)
    local info = {}
    info.tran = tran
    info.obj = obj
    info.key = key
    self.modInfoDic[tostring(key)] = info
end

--1.神秘宝藏
--2.宝藏秘境
--3.宝藏商城
function M:OpenTab(index)
    self.index = tostring(index)
    UIMgr.Open(UITreaFever.Name)
    self:InitTogs()
    self:UpAction()
end

--打开分页
function M:OpenTabByIdx(t1,t2,t3,t4)
    self.index = tostring(t1)
    self:InitTogs()
    self:UpAction()
end

--清理缓存
function M:Clear()
    -- for k,v in pairs(self.modDic) do
    --   v:Clear()
    -- end
    self.index = nil
    self.dic = nil
    self.curIndex = 0
end

-- function M:Update()
--     self.modDic["1"]:Update()
-- end

--释放资源
function M:DisposeCustom()
    -- self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.modDic)
    TableTool.ClearDic(self.modInfoDic)
    TreaFeverMgr.isFirstOpen=false
    TreaFeverMgr:SetAllRed()
end

return M