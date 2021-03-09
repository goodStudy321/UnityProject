UIFestivalAct = UIBase:New{Name = "UIFestivalAct"}

require("UI/UIFestivalAct/ActToggle")
require("UI/UIFestivalAct/UIActComViewF")
require("UI/UIFestivalAct/UIActComViewT")
require("UI/UIFestivalAct/UIActComViewCZ")
require("UI/UIFestivalAct/UIActComViewSD")
require("UI/UIFestivalAct/UIActComViewNN")
require("UI/UIFestivalAct/UIComViewTh")
require("UI/UIFestivalAct/UIActComViewHY")
require("UI/UIFestivalAct/UIActComViewLC")
require("UI/UIFestivalAct/UIActComViewCR")
require("UI/UIFestivalAct/UIActComViewQX")

local M = UIFestivalAct

M.toggleList = {}

function M:InitCustom()
    local FC =TransTool.FindChild
    local G = ComTool.Get
    local trans = self.root

    self.grid = G(UIGrid, trans, "ToggleGroup")
    self.prefab = FC(self.grid.transform, "Toggle")
    self.prefab:SetActive(false)

    self.comViewF = ObjPool.Get(UIActComViewF)
    self.comViewF:Init(FC(trans, "ComViewF"))

    self.comViewT = ObjPool.Get(UIActComViewT)
    self.comViewT:Init(FC(trans, "ComViewT"))

    self.comViewTh = ObjPool.Get(UIComViewTh)
    self.comViewTh:Init(FC(trans, "ComViewTh"))

    self.comViewCZ = ObjPool.Get(UIActComViewCZ)
    self.comViewCZ:Init(FC(trans, "ComViewCZ"))

    self.comViewNN = ObjPool.Get(UIActComViewNN)
    self.comViewNN:Init(FC(trans, "ComViewNN"))

    self.comViewSD = ObjPool.Get(UIActComViewSD)
    self.comViewSD:Init(FC(trans, "ComViewSD"), 0)

    self.comViewJH = ObjPool.Get(UIActComViewSD)
    self.comViewJH:Init(FC(trans, "ComViewJH"), 1)

    self.comViewHY = ObjPool.Get(UIActComViewHY)
    self.comViewHY:Init(FC(trans, "ComViewLP"))

    self.comViewLC = ObjPool.Get(UIActComViewLC)
    self.comViewLC:Init(FC(trans, "ComViewLP"))

    self.comViewCR = ObjPool.Get(UIActComViewCR)
    self.comViewCR:Init(FC(trans,"ComViewCR"))

    self.comViewQX = ObjPool.Get(UIActComViewQX)
    self.comViewQX:Init(FC(trans,"ComViewQX"))

    UITool.SetLsnrClick(trans, "BtnClose", self.Name, self.Close, self)
   
    self:UpdateToggleList()
    self:SwitchTab(self.selectType)
    self:SetLnsr("Add")
    FestivalActMgr:HideNorAction()
end

function M:SetLnsr(key)
    local mgr = FestivalActMgr
    PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
    mgr.eUpdateActTime[key](mgr.eUpdateActTime, self.UpdateActTime, self)
    mgr.eUpdateActDisplay[key](mgr.eUpdateActDisplay, self.UpdateActDisplay, self)
    mgr.eUpdateActItemList[key](mgr.eUpdateActItemList, self.UpdateActItemList, self)
    mgr.eUpdateItemRemainCount[key](mgr.eUpdateItemRemainCount, self.UpdateItemRemainCount, self)
    mgr.eUpdateActImg[key](mgr.eUpdateActImg, self.UpdateActImg, self)
    mgr.eUpdateRedPoint[key](mgr.eUpdateRedPoint, self.UpdateRedPoint, self)
    mgr.eUpdateActSort[key](mgr.eUpdateActSort, self.UpdateActSort, self)
end

function M:UpdateActSort()
    self:UpdateToggleList()
    self:UpdateTogState(self.curType)
end

function M:UpdateRedPoint(state, type)
    local list = self.toggleList
    for i=1,#list do
        if list[i].data.type == type then
            list[i]:SetRedPoint(state)
            break
        end
    end
end

function M:UpdateActImg(type)
    if type == self.curType then
        self.curView:UpdateImg()
    end
end


function M:UpdateItemRemainCount(type)
    if type == self.curType then
        self.curView:UpdateItemRemainCount()
    end
end


function M:UpdateActItemList(type)
    if type == self.curType then
        self.curView:UpdateItemList()
    end
end


function M:UpdateActTime(type)
    if type == self.curType then
        self.curView:UpdateTimer()
    end
end

function M:UpdateActDisplay(type)
    if type == self.curType then
        self.curView:UpdateActDisplay()
    end
    self:UpdateToggleList()
end

--道具添加
function M:OnAdd(action,dic)
    local list = {10156, 10356, 10357, 10410, 10418, 10419}
    local isShow = false
    if action >= 10151 and action <= 10153 then
        isShow = true
    end
    for i,v in ipairs(list) do
        if action == v then
            isShow = true
            break
        end
    end
    if isShow then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
    end
end

--显示奖励的回调方法
function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.dic)
	end
end

function M:Show(type)
    self.selectType = type
    UIMgr.Open(self.Name)
end

function M:SwitchTab(type)
    self:OnToggleClick(type or self.toggleList[1].data.type)
end

function M:CreateToggle(data)
    if data.type == FestivalActMgr.XYC or data.type == FestivalActMgr.LDL
    or data.type == FestivalActMgr.SMBZ or data.type == FestivalActMgr.BZFB
    or data.type == FestivalActMgr.BZSC then return end
    local go = Instantiate(self.prefab)
    TransTool.AddChild(self.grid.transform, go.transform)
    local tog = ObjPool.Get(ActToggle)
    tog:Init(go)
    tog:SetActive(true)
    tog:UpdateData(data)
    tog.eClick:Add(self.OnToggleClick, self)
    table.insert(self.toggleList, tog)
end

function M:UpdateToggleList()
    local data = FestivalActMgr:GetToggleInfo()
    local len = #data
    local list = self.toggleList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateToggle(data[i])
        end
    end
    self.grid:Reposition()
end

function M:UpdateTogState(type)
    local list = self.toggleList
    for i=1,#list do
        list[i]:SetHighlight(list[i].data.type==type)
    end
end

function M:OnToggleClick(type)
    if self.curType and self.curType == type then return end
	local info = FestivalActMgr:GetActInfo(type)
	if not info then return end
    self.curType = type
    self:UpdateTogState(type)
    if self.curView then
        self.curView:Close()
    end

    if type == FestivalActMgr.ExpDB or type == FestivalActMgr.BossDrop or type == FestivalActMgr.CZSB then
        self.curView = self.comViewT
    elseif type == FestivalActMgr.CZYL then
        self.curView = self.comViewCZ
    elseif type == FestivalActMgr.QMSD then
        if info.template == 0 then
            self.curView = self.comViewSD
        else
            self.curView = self.comViewJH
        end
    elseif type == FestivalActMgr.LCLP then
        self.curView = self.comViewLC
    elseif type == FestivalActMgr.HYLP then
        self.curView = self.comViewHY
    elseif type == FestivalActMgr.LJXF or type == FestivalActMgr.LJCZ then
		self.curView = self.comViewF
    elseif type == FestivalActMgr.NNWN then
        self.curView = self.comViewNN	
    elseif type == FestivalActMgr.DLYL or type == FestivalActMgr.CopyDb or
           type == FestivalActMgr.LCDL or type == FestivalActMgr.DCDL then
        self.curView = self.comViewTh
    elseif type == FestivalActMgr.XFPH then
        self.curView = self.comViewCR
    elseif type == FestivalActMgr.YJQX then
        self.curView = self.comViewQX
    end
    self.curView:Open(info)
    self:UpTogNorAction(type)
end

--更新默认红点
function M:UpTogNorAction(type)
    local mgr = FestivalActMgr
    local dic = mgr.norActionDic
    for i,v in ipairs(self.toggleList) do
        if type == v.data.type then
            local key = tostring(type)
            local state = FestivalActMgr:GetRedPointState(type)
            if dic[key] and state == false then
                v:SetRedPoint(false)
            end
        end
    end
    mgr:UpNorAction(type)
end

--实时更新
function M:Update()
    self.comViewLC:Update()
    self.comViewHY:Update()
    self.comViewTh:Update();
end

function M:DisposeCustom()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.toggleList)
    ObjPool.Add(self.comViewF)
    ObjPool.Add(self.comViewT)
    ObjPool.Add(self.comViewCZ)
    ObjPool.Add(self.comViewSD)
    ObjPool.Add(self.comViewNN)
    ObjPool.Add(self.comViewHY)
    ObjPool.Add(self.comViewLC)
    ObjPool.Add(self.comViewCR)
    ObjPool.Add(self.comViewQX)
    ObjPool.Add(self.comViewJH)
    self.comViewF = nil
    self.comViewT = nil
    self.comViewCZ = nil
    self.comViewSD = nil
    self.comViewNN = nil
    self.comViewHY = nil
    self.comViewLC = nil
    self.comViewCR = nil
    self.comViewQX = nil
    self.comViewJH = nil
    self.curView = nil
    self.dic = nil
    self.curType = nil
    self.selectType = nil
    FestivalActMgr:UpdateAllRedPoint()
end

return M