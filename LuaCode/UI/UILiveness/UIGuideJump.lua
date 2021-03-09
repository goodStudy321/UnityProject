--[[
 	authors 	:Liu
 	date    	:2019-4-13 19:02:00
 	descrition 	:引导跳转界面
--]]

UIGuideJump = UIBase:New{Name = "UIGuideJump"}

local My = UIGuideJump

require("UI/UILiveness/UIGuideJumpMenu")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.modList = {}
    self.togList = {}
    self.actionList = {}
    self.strList = {"我要装备", "我要经验", "我要绑元"}

    local module1 = Find(root, "Module1", des)
    self:InitModule(module1, UIGuideJumpMenu)

    self.tog = FindC(root, "ActivModule/Grid/tog1", des)

    SetB(root, "CloseBtn", des, self.Close, self)

    self:InitTogs()

    self.modList[1]:UpCfg(1)
end

--点击Tog
function My:OnTog(go)
    local it = self.modList[1]
    local num = tonumber(go.name)
    it:UpCfg(num)
end

--初始化Togs
function My:InitTogs()
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local Add = TransTool.AddChild
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    local parent = self.tog.transform.parent
    for i=1, #self.strList do
        local go = Instantiate(self.tog)
        local tran = go.transform
        go.name = i
        local red = FindC(tran, "Action", self.Name)
        local lab1 = CG(UILabel, tran, "Label")
        local lab2 = CG(UILabel, tran, "Label1")
        local tog = CGS(UIToggle, tran, self.Name)
        lab1.text = self.strList[i]
        lab2.text = self.strList[i]
        Add(parent, tran)
        SetS(tran, self.OnTog, self, self.Name)
		table.insert(self.actionList, red)
		table.insert(self.togList, tog)
    end
    local index = self.index
	local num = (index) and index or 1
	self.togList[num].value = true
    self.tog:SetActive(false)
end

--初始化模块
function My:InitModule(module, class)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    table.insert(self.modList, mod)
end

--1.装备
--2.经验
--3.元宝
function My:OpenTab(index)
	self.index = index
    UIMgr.Open(UILivenessJump.Name)
end

--清理缓存
function My:Clear()
    self.index = nil
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    TableTool.ClearDicToPool(self.modList)
    JumpMgr.eOpenJump()
end

return My