--[[
 	authors 	:Liu
 	date    	:2018-12-5 09:55:00
 	descrition 	:结婚系统
--]]

UIMarry = UIBase:New{Name = "UIMarry"}

local My = UIMarry

local strs = "UI/UIMarry/"
require(strs.."UIMarryMod1")
require(strs.."UIMarryTitle")
require(strs.."UIMarryGivenIt")
require(strs.."UIMarryGiven")
require("Liveness/CustomBtn")
require("UI/UIMarry/UILoveCopy")
require("UI/UIMarry/UIKnot")
require("UI/MarriageTree/MarriageTreePanel")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.menuList = {}
    self.menuList[1] = FindC(root, "marryMenu", des)
    self.menuList[2] = FindC(root, "titleMenu", des)
    local menu0 = Find(root, "marryMenu", des)
    local btnGrid = Find(menu0, "btnGrid", des)
    local module1 = Find(menu0, "marryInfo", des)
    local module2 = Find(menu0, "LoveCopy", des)
    local module3 = Find(menu0, "knot", des)
    local module4 = Find(menu0, "MarriageTreePanel", des)
    local module5 = Find(menu0, "given", des)
    local btn = FindC(menu0, "btnGrid/btn", des)

    self.desBg = FindC(menu0, "marryInfo/desBg", des)
    self.btnGrid = FindC(menu0, "btnGrid", des)
    self.moduel = FindC(menu0, "marryInfo/moduel", des)
    self.spr = FindC(menu0, "marryInfo/Bg1/spr", des)

    self.labList = {"結婚", "副本", "同心结","姻缘树","仙侣互赠"}--------添加新按钮
    self.btnList = {}
    self.modList = {}
    self.actionList = {}
    
    SetB(menu0, "close", des, self.OnClose, self)
    self:InitModel1()
    self:InitModule(module1, UIMarryMod1)--------添加新模块
    self:InitModule(module2, UILoveCopy)
    self:InitModule(module3, UIKnot)
    self:InitModule(module4, MarriageTreePanel)
    self:InitModule(module5, UIMarryGiven)
    -- self:HideBtn(nil)---------------隐藏按钮
    
    self:InitBtns(btnGrid, btn)
    self:InitCoupleData()
    self:InitActionList()
    self:SetAction()
    self:InitTab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.eUpActionState[func](MarryMgr.eUpActionState, self.SetAction, self)
end

--初始化按钮
function My:InitBtns(btnGrid, btn)
    local Add = TransTool.AddChild
    for i,v in ipairs(self.labList) do
        local go = Instantiate(btn)
        local tran = go.transform
        Add(btnGrid, tran)
        local it = ObjPool.Get(CustomBtn)
        table.insert(self.btnList, it)
        it:Init(tran, i, v, self.btnList, self.modList)
    end
    btn:SetActive(false)
    btnGrid:GetComponent(typeof(UIGrid)):Reposition()
end

--初始化模块
function My:InitModule(module, class)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    table.insert(self.modList, mod)
end

--打开分页
function My:OpenTab(index)
    self.index = index
    UIMgr.Open(UIMarry.Name)
end

--打开分页(邮件专用)
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.index = t1
end

--初始化分页
function My:InitTab()
    local index = self.index
    local btnList = self.btnList
    local modList = self.modList
    if index then
        local it = btnList[index]
        local mod = modList[index]
        if it and mod then
            it:InitState(index)
        end
    else
        if btnList[1] then
            btnList[1]:InitState(1)
        end
    end
end

--隐藏按钮
function My:HideBtn(index)
    if index == nil then return end
    table.remove(self.modList, index)
    table.remove(self.labList, index)
end

--初始化仙侣数据
function My:InitCoupleData()
    local data = MarryInfo.data.coupleInfo
    if data then
        self.modList[1]:CreateModel2(data)
    end
end

--初始化称号界面
function My:InitModel1()
    self.title = ObjPool.Get(UIMarryTitle)
    self.title:Init(self.menuList[2].transform)
end

--设置界面状态
function My:SetMenuState(index)
    for i,v in ipairs(self.menuList) do
        if i == index then
            self.menuList[i]:SetActive(true)
        else
            self.menuList[i]:SetActive(false)
        end
    end
end

--设置玩法介绍界面状态
function My:SetDesState(state)
    self.desBg:SetActive(state)
    self.btnGrid:SetActive(not state)
    self.moduel:SetActive(not state)
    self.spr:SetActive(not state)
    self.modList[1]:UpNameGo(not state)
end

--点击关闭面板
function My:OnClose()
    if self.btnGrid.activeSelf then
        self:Close()
        JumpMgr.eOpenJump()
    else
        self:SetDesState(false)
    end
end

--初始化红点
function My:SetAction()
    for k,v in pairs(MarryMgr.actionDic) do
		self:UpAction(k, v)
	end
end

--更新红点状态
function My:UpAction(index, state)
	local list = self.actionList
	local go = list[tonumber(index)]
	if not go then
		iTrace.Error("SJ", "没有找到红点物体")
		return
	end
	go:SetActive(state)
end

--初始化红点列表
function My:InitActionList()
    for i,v in ipairs(self.btnList) do
        table.insert(self.actionList, v.action)
    end
end

--清理缓存
function My:Clear()
    self.index = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    ObjPool.Add(self.title)
    self.title = nil
    TableTool.ClearDicToPool(self.btnList)
    self.btnList = nil
    TableTool.ClearDicToPool(self.modList)
    self.modList = nil
    self:SetLnsr("Remove")
end

return My