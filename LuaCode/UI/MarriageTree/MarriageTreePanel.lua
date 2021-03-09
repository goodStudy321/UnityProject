require("UI/MarriageTree/HeadPhoto")
MarriageTreePanel = Super:New{Name = "MarriageTreePanel"}
local M = MarriageTreePanel

local US = UITool.SetLsnrSelf
local ED = EventDelegate

function M:Ctor()
    self.items = {}
end

function  M:Init(obj)
    self.go = obj.gameObject
    self.objTrans = self.go.transform
    local root = self.objTrans

    local C = ComTool.Get
    local T = TransTool.FindChild
    local des = self.Name

    self.tipLb = T(root,"Tip/TipLb")
    US(self.tipLb,self.ClickToTipClose,self,des, false)
    
    self.oneBtn1 = T(root,"Reward/OneBtn1")
    self.oneBtn2 = T(root,"Reward/OneBtn2")
    self.twoBtn1 = T(root,"Reward/TwoBtn1")
    self.twoBtn2 = T(root,"Reward/TwoBtn2")

    US(self.oneBtn1,self.ClickToOneGet,self,des)
    US(self.twoBtn1,self.ClickToDayGet,self,des)
    
    self.reqBtn = T(root,"Get/reqBtn")
    US(self.reqBtn,self.ClickToReqBtn,self,des)

    self.taBtn = T(root,"Get/taBtn")
    US(self.taBtn,self.ClickToTaBtn,self,des)

    self.reqBtnLb = C(UILabel,root,"Get/reqBtn/Label")
    self.taBtnLb = C(UILabel,root,"Get/taBtn/Label")

    self.tipBtn = T(root,"Tip/TipBtn")
    US(self.tipBtn,self.ClickToTipBtn,self,des)

    self.selfPhotoObj = T(root,"Get/SelfPhoto")
    self.selfPhoto = ObjPool.Get(HeadPhoto)
    self.selfPhoto:Init(self.selfPhotoObj)

    self.taPhotoObj = T(root,"Get/TaPhoto")
    self.taPhoto = ObjPool.Get(HeadPhoto)
    self.taPhoto:Init(self.taPhotoObj)

    self.oneReward = T(root,"Reward/Item1/1")
    self.dailyReward1 = T(root,"Reward/Item2/2")
    self.dailyReward2 = T(root,"Reward/Item3/3")

    self.Lb1 = C(UILabel,root,"Reward/Item1/Label")
    self.Lb2 = C(UILabel,root,"Reward/Item2/Label")
    self.Lb3 = C(UILabel,root,"Reward/Item3/Label")

    -- 动画
    self.tween1 = C(UITweener,root,"Reward/OneBtn1")
    self.tween2 = C(UITweener,root,"Reward/TwoBtn1")

    -- 红点
    self.redTa = T(root,"Get/taBtn/RedTip")
    self.redReq = T(root,"Get/reqBtn/RedTip")

    -- 领取特效
    self.oneGetRed = T(root,"Reward/OneBtn1/FX_tishi01")
    self.dayGetRed = T(root,"Reward/TwoBtn1/FX_tishi01")

    ED.Add(self.tween1.onFinished, ED.Callback(self.OneComplete, self))
    ED.Add(self.tween2.onFinished, ED.Callback(self.DayComplete, self))

    self.getTy1 = self.oneBtn1.transform.localPosition.y
    self.getTy2 = self.twoBtn1.transform.localPosition.y

    self.reqAct = false
    self.taAct = false

    self:InitRewardItem()
    self:InitStatus()
    self:ShowHeadPT()
    
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    MarriageTreeMgr.eChangeTaBtn[key](MarriageTreeMgr.eChangeTaBtn,self.ChangeTaBtn,self)
    MarriageTreeMgr.eChangeReqBtn[key](MarriageTreeMgr.eChangeReqBtn,self.ChangeReqBtn,self)
    MarriageTreeMgr.eChangeRewardBtn[key](MarriageTreeMgr.eChangeRewardBtn,self.ChangeRewardBtn,self)
    MarriageTreeMgr.eUpdateRewardItem[key](MarriageTreeMgr.eUpdateRewardItem,self.UpdateRewardItem,self)
    MarryMgr.eDivorce[key](MarryMgr.eDivorce, self.DivorceStatus, self)
end

function M:ShowHeadPT()
    local selfCategory = User.MapData.Category
    self.selfPhoto:Choose(selfCategory,true)
    local isMarry = MarryInfo.data.coupleInfo
    if not isMarry then
        self.taPhoto:Choose("",false)
    else
        local taCategory = MarryInfo.data.coupleInfo.category
        self.taPhoto:Choose(taCategory,true)
    end
end

function M:InitStatus()
    self:ChangeRewardBtn()
    self:ChangeTaBtn()
    self:ChangeReqBtn()
    self:UpdateRewardItem()
end

-- 离婚状态改变
function M:DivorceStatus()
    MarryInfo.data.treeEndTime = 0
    MarryInfo.data.treeIsAward = false
    MarryInfo.data.treeDailyTime = 0
    MarryInfo.data.coupleTreeEndTime = 0
    self:ChangeRewardBtn()
    self:ChangeTaBtn()
    self:ChangeReqBtn()
    self:UpdateRewardItem()
    self:ShowHeadPT()
end

-- 初始化奖励格子
function M:InitRewardItem()
    self.rewardList = MarriageTreeMgr:GetReward()
    self.parentList = {self.oneReward,self.dailyReward1,self.dailyReward2}
    self.LbList = {self.Lb1,self.Lb2,self.Lb3}
    for i,v in ipairs(self.parentList) do
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(v.transform,0.8)
        local num = self.rewardList[i].value
        self.LbList[i].text = num
        self.item:UpData(self.rewardList[i].id,"",false)
        self.item.Lab.fontSize = 26
        self.item.Qua.enabled = false
        self.items[#self.items + 1] = self.item
    end
end

-- 更新奖励格子
function M:UpdateRewardItem()
    local selfLerp = MarriageTreeMgr:GetTimeLerp(1)
    local isGetisReward = MarryInfo.data.treeIsAward
    if selfLerp > 0 then
        if isGetisReward == false then
            self.items[1]:SetGray(true,true)
        else
            self.items[1]:SetGray(false,false)
        end
        local isSame = MarriageTreeMgr:isSameDay()
        if isSame == false then
            for i=2,3 do
                self.items[i]:SetGray(false,false)
            end
        else
            for i=2,3 do
                self.items[i]:SetGray(true,true)
            end
        end
    else
        for i=1,3 do
            self.items[i]:SetGray(false,false)
        end
    end
end

-- 改变为他种树按钮
function M:ChangeTaBtn()
    local selfLerp = MarriageTreeMgr:GetTimeLerp(0)
    if selfLerp > 0 then
        local day = DateTool.GetDay(selfLerp)+1
        self.taBtnLb.text = "剩余"..day.."天"
        self:SetFalse(1,false)
        self:SetNoClick(self.taBtn,false)
    else
        self.taBtnLb.text = "为TA种树"
        self:SetNoClick(self.taBtn,true)
        local isMarry = MarryInfo.data.coupleInfo
        if isMarry then
            local taAct = MarriageTreeMgr.taAct
            self:SetFalse(1,taAct)
        else
            self:SetFalse(1,false)
        end
    end
end

-- 改变请求种树按钮
function M:ChangeReqBtn()
    local selfLerp = MarriageTreeMgr:GetTimeLerp(1)
    if selfLerp > 0 then
        local day = DateTool.GetDay(selfLerp)+1
        self.reqBtnLb.text = "剩余"..day.."天"
        self:SetFalse(0,false)
        self:SetNoClick(self.reqBtn,false)
    else
        self.reqBtnLb.text = "请求种树"
        self:SetNoClick(self.reqBtn,true)
        local isMarry = MarryInfo.data.coupleInfo
        if isMarry then
            local reqAct = MarriageTreeMgr.reqAct
            self:SetFalse(0,reqAct)
        else
            self:SetFalse(0,false)
        end
    end
end

function M:SetFalse(num,bool)
    if num == 0 then
        self.redReq:SetActive(bool)
        MarriageTreeMgr.reqAct = bool
    elseif num == 1 then
        self.redTa:SetActive(bool)
        MarriageTreeMgr.taAct = bool
    elseif num == 2 then
        self.oneGetRed:SetActive(bool)
        MarriageTreeMgr.getOne = bool
    elseif num == 3 then
        self.dayGetRed:SetActive(bool)
        MarriageTreeMgr.getTwo = bool
    end
    MarriageTreeMgr:SetActive()
end


-- 改变领取奖励按钮
function M:ChangeRewardBtn()
    local selfLerp = MarriageTreeMgr:GetTimeLerp(1)
    local isGetisReward = MarryInfo.data.treeIsAward
    if selfLerp > 0 then
        self.oneBtn1:SetActive(isGetisReward)
        self.oneBtn2:SetActive(not isGetisReward)
        self:SetFalse(2,isGetisReward)
        local isSame = MarriageTreeMgr:isSameDay()
        self.twoBtn1:SetActive(not isSame)
        self.twoBtn2:SetActive(isSame)
        self:SetFalse(3,not isSame)
    else
        self.oneBtn1:SetActive(true)
        self.oneBtn2:SetActive(false)
        self.twoBtn1:SetActive(true)
        self.twoBtn2:SetActive(false)
        self:SetFalse(2,false)
        self:SetFalse(3,false)
    end
    MarriageTreeMgr:SetActive()
end

-- 设置不可点击状态
function M:SetNoClick(go,isCilck)
    local box = go:GetComponent(typeof(BoxCollider))
    box.enabled = isCilck
end

-- 种树立得、每日结果按钮动画
-- 0为种树立得  1为每日结果
function M:PlayTween(num)
    self.num = num
    if num == 0 then
        self.tween1:PlayForward()
    else
        self.tween2:PlayForward()
    end
end

function M:OneComplete()
    local y = self.oneBtn1.transform.localPosition.y
    if self.getTy1 == y then
        MarriageTreeMgr:ReqReward()
        self:SetFalse(2,false)
    else
        self.tween1:PlayReverse()
    end
end

function M:DayComplete()
    local y = self.twoBtn1.transform.localPosition.y
    if self.getTy2 == y then
        MarriageTreeMgr:ReqReward()
        self:SetFalse(3,false)
    else
        self.tween2:PlayReverse()
    end
   
end

-- 种树立得按钮点击事件
function M:ClickToOneGet()
    MarriageTreeMgr:SetBtnType(1)
    local selfLerp = MarriageTreeMgr:GetTimeLerp(1)
    if selfLerp > 0 then
        self:PlayTween(0)
    else
        UITip.Log("尚未种树")
    end
end

-- 每日结果点击事件
function M:ClickToDayGet()
    MarriageTreeMgr:SetBtnType(2)
    local selfLerp = MarriageTreeMgr:GetTimeLerp(1)
    if selfLerp > 0 then
        self:PlayTween(1)
    else
        UITip.Log("尚未种树")
    end
end

-- 请求种树
function M:ClickToReqBtn()
    local isMarry = MarryInfo.data.coupleid
    
    if isMarry ~= 0 then
        for i,v in ipairs(FriendMgr.FriendList) do
            if isMarry == tonumber(v.ID) then
                if v.Online == false then
                    UITip.Log("您的仙侣不在线")
                else
                    MarriageTreeMgr:ReqTree()
                end
            end
        end
    else
        self:OpenTip(false,true,"您尚未拥有仙侣","确定")
    end
    self:SetFalse(0,false)
end

-- 为他种树
function M:ClickToTaBtn()
    local isMarry = MarryInfo.data.coupleid
    if isMarry ~= nil and isMarry > 0 then
        local taName = ""
        if (MarryInfo.data.coupleInfo ~= nil) then
             taName = MarryInfo.data.coupleInfo.name
        end
        self:OpenTip(true,false,"即将为你的另一半"..taName.."种下一棵姻缘树，种植花费520元宝","确定","取消")
    else
        self:OpenTip(false,true,"您尚未拥有仙侣","确定")
    end
    self:SetFalse(1,false)
end

function M:ClickToTipBtn()
    self.tipLb:SetActive(true)
end

function M:ClickToTipClose()
    self.tipLb:SetActive(false)
end

function M:OpenTip(isBtn1,isBtn2,tipLb,yesBtnLb,noBtnLb)
    UIMgr.Open(MarrTipPanel.Name)
    MarrTipPanel:ChangeBtnLbAndLb(isBtn1,isBtn2,tipLb,yesBtnLb,noBtnLb)
end

function M:Dispose()
    while #self.items > 0 do
        local item = self.items[#self.items]
        item:SetGray(false,false)
        item.Qua.enabled = true
        item:DestroyGo()
        ObjPool.Add(item)
        self.items[#self.items] = nil
    end

    if self.selfPhoto ~= nil then
        ObjPool.Add(self.selfPhoto)
        self.selfPhoto = nil
    end
    if self.taPhoto ~= nil then
        ObjPool.Add(self.taPhoto)
        self.taPhoto = nil
    end
    self:SetLsnr("Remove")
    TableTool.ClearDic(self.parentList)
    TableTool.ClearDic(self.LbList)
    TableTool.ClearUserData(self)
end


return M