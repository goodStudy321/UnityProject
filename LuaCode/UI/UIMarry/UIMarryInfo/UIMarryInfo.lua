--[[
 	authors 	:Liu
 	date    	:2018-12-10 17:00:00
 	descrition 	:结婚信息界面
--]]

UIMarryInfo = UIBase:New{Name = "UIMarryInfo"}

local My = UIMarryInfo

local strs = "UI/UIMarry/UIMarryInfo/"
require(strs.."UIProposeType")
require(strs.."UIMarryFeast")
require(strs.."UIMarryInfoMenu")
require(strs.."UIMarryStoreMenu")
require(strs.."UIMarryDivorce")

My.eSHow = Event()

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick

    self.menuList = {}
    self.menuList[1] = FindC(root, "model1", des)
    self.menuList[2] = FindC(root, "proposeType", des)
    self.menuList[3] = FindC(root, "marryFeast", des)
    self.menuList[4] = FindC(root, "InfoMenu", des)
    self.menuList[5] = FindC(root, "StoreMenu", des)
    self.menuList[6] = FindC(root, "DivorceMenu", des)
    self.go = root.gameObject

    SetB(root, "model1/btns/close", des, self.OnClose, self)
    
    self:InitBtns(root, des)
    self:InitMenu()
    self:InitTab()
end

--初始化按钮
function My:InitBtns(root, des)
    local SetS = UITool.SetLsnrSelf
    local Find = TransTool.Find
    for i=1, 6 do
        local path = "model1/btns/btn"..i
        local btn = Find(root, path, des)
        SetS(btn, self.OnTog, self, des)
    end
end

--点击Tog
function My:OnTog(go)
    if go.name == "btn1" then
        self:OnBtn1()
    elseif go.name == "btn2" then
        self:OnBtn2()
    elseif go.name == "btn3" then
        self:OnBtn3()
    elseif go.name == "btn4" then
        self:OnBtn4()
    elseif go.name == "btn5" then
        self:OnBtn5()
    elseif go.name == "btn6" then
        self:OnBtn6()
    end
end

--点击我要提亲
function My:OnBtn1()
    self:SetMenuState(2)
end

--点击缔结姻缘
function My:OnBtn2()
    if MarryInfo:IsMarry() then
        UIProposePop:OpenTab(2, true)
    else
        UITip.Log("您未有仙侣")
    end
end

--点击预约婚礼
function My:OnBtn3()
    if MarryInfo:IsMarry() then
        self:SetMenuState(3)
    else
        UITip.Log("您未有仙侣")
    end
end

--点击邀请宾客
function My:OnBtn4()
    if MarryInfo:IsAppoint() then
        UIProposePop:OpenTab(4, true)
    else
        UITip.Log("需要先预约婚礼才可以邀请宾客")
    end
end

--点击举办宴会
function My:OnBtn5()
    if MarryInfo:IsAppoint() then
        UIProposePop:OpenTab(5, true)
    else
        UITip.Log("当前无预约婚礼")
    end
end

--点击神仙眷侣
function My:OnBtn6()
    if MarryInfo:IsMarry() then
        UIProposePop:OpenTab(7)
    else
        UITip.Log("您未有仙侣")
    end
end

--设置界面状态
function My:SetMenuState(index)
    for i,v in ipairs(self.menuList) do
        if i == index then
            self.menuList[i]:SetActive(true)
            My.eSHow(index)
        else
            self.menuList[i]:SetActive(false)
        end
    end
end

--打开分页
function My:OpenTab(index)
    self.index = index
    UIMgr.Open(UIMarryInfo.Name)
end

--初始化分页
function My:InitTab()
    local index = self.index
    if index then
        self:SetMenuState(index)
    else
        self:SetMenuState(1)
    end
end

--打开婚礼商城
function My:OpenStore()
    self:OpenTab(5)
    self.storeMenu:SetIsBack()
end

--初始化界面
function My:InitMenu()
    self.pType = ObjPool.Get(UIProposeType)
    self.pType:Init(self.menuList[2].transform)
    self.feast = ObjPool.Get(UIMarryFeast)
    self.feast:Init(self.menuList[3].transform)
    self.infoMenu = ObjPool.Get(UIMarryInfoMenu)
    self.infoMenu:Init(self.menuList[4].transform)
    self.storeMenu = ObjPool.Get(UIMarryStoreMenu)
    self.storeMenu:Init(self.menuList[5].transform)
    self.divorce = ObjPool.Get(UIMarryDivorce)
    self.divorce:Init(self.menuList[6].transform)
end

--点击关闭
function My:OnClose()
    self:SetMenuState(4)
end

--清理缓存
function My:Clear()
    self.index = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    ObjPool.Add(self.pType)
    self.pType = nil
    ObjPool.Add(self.feast)
    self.feast = nil
    ObjPool.Add(self.infoMenu)
    self.infoMenu = nil
    ObjPool.Add(self.storeMenu)
    self.storeMenu = nil
    ObjPool.Add(self.divorce)
    self.divorce = nil
end

return My