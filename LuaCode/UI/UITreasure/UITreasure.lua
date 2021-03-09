--[[
 	authors 	:Liu
 	date    	:2018-6-27 10:50:00
 	descrition 	:寻宝活动界面
--]]

UITreasure = UIBase:New{Name = "UITreasure"}

local My = UITreasure

require("UI/UITreasure/UIRuneTreas")
require("UI/UITreasure/UIEquipTreas")

function My:InitCustom()
    local root, des = self.root, self.Name
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    local Find = TransTool.Find
    local CG = ComTool.Get

    self.AssetMgr = Loong.Game.AssetMgr
    self.root = root
    self.togList = {}
    self.redDotList = {}

    self.grid = CG(UIGrid, root, "activityModule/togBg/Grid")
    self.bg = FindC(root, "mask", des)
    self.bg1 = FindC(root, "mask1", des)
    self.maskBox = FindC(root, "maskBox", des)
    self.modelCam = Find(root, "modelCam", des)
    self.oldPos = self.modelCam.localPosition

    --符文寻宝
    self.tran1 = Find(root, "activityModule", des)
    self.tran2 = Find(root, "runeTreasure/BottomBg", des)
    self.tran3 = Find(root, "close", des)

    SetB(root, "close", des, self.OnClose, self)
    SetB(root, "maskBox", des, self.OnMask, self)

    self:SetLnsr("Add")

    local index = (self.openIndex==nil) and 1 or self.openIndex
    if self.openIndex == nil then self:OpenTab(index) end
end

--更新
function My:Update()
    if self.equip then
        self.equip:Update()
        self.equip:UpModelRotation()
    end
    if self.rune then
        self.rune:Update()
    end
    if self.top then
        self.top:Update()
        self.top:UpTopModelRotation()
    end
end

--设置监听
function My:SetLnsr(func)
    local mgr = TreasureMgr
    mgr.eUpRuneTreas[func](mgr.eUpRuneTreas, self.RespUpRuneTreas, self)
    mgr.eUpSTreasLogs[func](mgr.eUpSTreasLogs, self.RespUpSTreasLogs, self)
end

--响应更新符文寻宝
function My:RespUpRuneTreas()
    self.rune:UpTokenLab()
    self.rune.rune:UpTreasStste(false)
    self.rune.rune:UpShowPrice()
    self:UpRedDot()
    self.rune:PlayAnim()
end

--响应更新自身寻宝日志
function My:RespUpSTreasLogs()
    self:UpRedDot()
    if self.equip then
        self.equip:UpRedDot()
        self.equip:PlayAnim()
    end
    if self.top then
        self.top:UpRedDot()
        self.top:PlayAnim()
    end
end

--相机震动特效
--amplitude（震幅-单位米）
function My:CameraShakeEff(amplitude)
    local cam = self.modelCam
    local posX = cam.localPosition.x
    local num = math.random()
    local val = (posX >= 0) and -1 or 1
    cam.localPosition = cam.localPosition + Vector3(num, num, num) * amplitude * val
end

--重置位置
function My:ResetPos()
    self.modelCam.localPosition = self.oldPos
end

--点击遮罩
function My:OnMask()
    if self.equip then self.equip:StopAnim() end
    if self.top then self.top:StopAnim() end
end

--更新遮罩
function My:UpMaskBox(state)
    self.maskBox:SetActive(state)
end

--初始化按钮
function My:InitTog()
    if self.root == nil then self:Close() return end
    local CG = ComTool.Get
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    local str = "activityModule/togBg/Grid/"
    for i=1, 3 do
        local tog = CG(UIToggle, self.root, str.."tog"..i)
        local redDot = FindC(self.root, str.."tog"..i.."/redDot", self.Name)
        SetS(tog.transform, self.OnTog, self, self.Name)
        table.insert(self.togList, tog)
        table.insert(self.redDotList, redDot)
    end
    local num1 = self:IsHideBtn(504, 2)
    local num2 = self:IsHideBtn(60, 3)
    local list = {1, num1, num2}
    local index = self.openIndex
    for i,v in ipairs(list) do
        if v == index then
            self:SwitchMenu(index)
            self.togList[index].value = true
            break
        end
    end
    self.grid:Reposition()
end

--是否隐藏按钮
function My:IsHideBtn(id, index)
    local isOpen = OpenMgr:IsOpen(id)
    self.togList[index].gameObject:SetActive(isOpen)
    local num = (isOpen) and index or 1
    return num
end

--切换界面
function My:SwitchMenu(index)
    local info = TreasureInfo
    if index == 1 then
        if not self.equip then
            self.equip = self:InitModule("equipTreasure", UIEquipTreas, info.equip)
        end
    elseif index == 2 then
        if not self.rune then
            self.rune = self:InitModule("runeTreasure", UIRuneTreas, info.rune)
        end
    elseif index == 3 then
        if not self.top then
            self.top = self:InitModule("topTreasure", UIEquipTreas, info.top)
        end
    end
end

--点击按钮
function My:OnTog(go)
    local index = tonumber(string.sub(go.name, 4))
    self.curIndex = index
    self:SwitchMenu(index)
    TreasureMgr:SetTopAction()
    self:UpRedDot()
    self:UpBg(index~=2)
end

--1.装备寻宝
--2.符文寻宝
--3.巅峰寻宝
function My:OpenTab(index)
    local isOpen = false
    local tip = ""
    if index == 1 then
        isOpen = UITabMgr.IsOpen(ActivityMgr.XB)
        tip="装备寻宝"
    elseif index == 2 then
        isOpen = OpenMgr:IsOpen(504)
    elseif index == 3 then
        isOpen = OpenMgr:IsOpen(60)
    end
    if not isOpen then UITip.Log(tip.."系统未开启") return end
    self.openIndex = index
    self.curIndex = index
    UIMgr.Open(UITreasure.Name)
    self:InitData(index)
end

--特殊的打开方式
function My:GetSpecial(t1)
    local isOpen = false
    if t1 == 1 then
        isOpen = UITabMgr.IsOpen(ActivityMgr.XB)
    elseif t1 == 2 then
        isOpen = OpenMgr:IsOpen(504)
    elseif t1 == 3 then
        isOpen = OpenMgr:IsOpen(60)
    end
    if isOpen == false then UITip.Log("系统未开启") return end
    return isOpen
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.openIndex = t1
    self.curIndex = t1
    self:InitData(t1)
end

--初始化数据
function My:InitData(num)
    self:InitTog()
    self:UpRedDot()
    self:UpBg(num~=2)
end

--初始化模块
function My:InitModule(path, obj, index)
    local tran = TransTool.Find(self.root, path, self.Name)
    local go = ObjPool.Get(obj)
    go:Init(tran, index)
    return go
end

--更新红点状态
function My:UpRedDot()
    for k,v in pairs(TreasureMgr.actionDic) do
        local index = tonumber(k)
        if self.redDotList == nil or #self.redDotList < 1 then return end
        if self.redDotList[index] == nil then self:Close() return end
        self.redDotList[index]:SetActive(v)
        if self.rune then
            self.rune.rune:UpRedDot(index, v)
        end
    end
end

--更新背景
function My:UpBg(state)
    if(self.bg == nil)  then return end
    self.bg:SetActive(state)
    self.bg1:SetActive(not state)
end

--更新Z轴坐标
function My:UpZPos(isTop)
    local pos1 = self.tran1.localPosition
    local pos2 = self.tran2.localPosition
    local pos3 = self.tran3.localPosition
    local num = (isTop==true) and 10000 or 0
    self.tran1.localPosition = Vector3(pos1.x, pos1.y, num)
    self.tran2.localPosition = Vector3(pos2.x, pos2.y, num)
    self.tran3.localPosition = Vector3(pos3.x, pos3.y, num)
end

--点击关闭
function My:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

--清理缓存
function My:Clear()
    local mgr = TreasureMgr
    mgr.isShow = false
    mgr:UpRedDot()
end

--重写释放资源
function My:DisposeCustom()
    self:Clear()
    ObjPool.Add(self.rune)
    self.rune = nil
    ObjPool.Add(self.equip)
    self.equip = nil
    ObjPool.Add(self.top)
    self.top = nil
    self.openIndex = nil
    self.curIndex = nil
    self:SetLnsr("Remove")
end

return My