--[[
 	authors 	:Liu
 	date    	:2019-1-14 12:00:00
 	descrition 	:许愿池
--]]

UIWish = UIBase:New{Name = "UIWish"}

local My = UIWish

local strs = "UI/UIWish/"
require(strs.."UIWishPanel1")
require(strs.."UIWishPanel2")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local S =  UITool.SetLsnrSelf

    self.cellList1 = {}
    self.cellList2 = {}
    self.actionList = {}
    self.curCfg = GlobalTemp["112"]
    if self.curCfg == nil then return end

    self.spr = Find(root, "PopPanel/spr", des)
    self.panelTran1 = Find(root, "Panel1", des)
    self.panelTran2 = Find(root, "Panel2", des)
    self.tween = CG(TweenScale, root, "PopPanel/spr")
    self.lab = CG(UILabel, root, "PopPanel/spr/lab")
    self.wishCount = CG(UILabel, root, "countLab/lab")
    self.tokenCount = CG(UILabel, root, "token/lab")
    self.unitPrice = CG(UILabel, root, "btn1/lab2")
    self.fullPrice = CG(UILabel, root, "btn2/lab2")
    self.tex = CG(UITexture, root, "token")
    self.timeLab = CG(UILabel, root, "timeLab")
    self.goldLab = CG(UILabel, root, "gold/lab")
    self.mask = FindC(root, "mask", des)
    self.awardItem1 = FindC(root, "award1/Scroll View/Grid/item", des)
    self.awardItem2 = FindC(root, "award2/Scroll View/Grid/item", des)
    self.luckBg = FindC(root, "LuckValBg", des)
    self.slider = CG(UISlider, root, "LuckValBg/sliderBg/slider")
    self.sliderLab = CG(UILabel, root, "LuckValBg/sliderBg/lab")

    self.hinttog = CG(UIToggle, root, "hint/bg/showhint", des, false);
    S(self.hinttog.transform, self.OnTog, self);
    self.hinttog.value = false;
    self.clickBtn = 0;

    self.hint = FindC(root, "hint", des);
    self.hint:SetActive(false);

    for i=1, 4 do
        local str = string.format("btn%s/redDot", i)
        local action = FindC(root, str, des)
        table.insert(self.actionList, action)
    end

    SetB(root, "btn1", des, self.OnBtn1, self)
    SetB(root, "btn2", des, self.OnBtn2, self)
    SetB(root, "btn3", des, self.OnBtn3, self)
    SetB(root, "btn4", des, self.OnBtn4, self)
    SetB(root, "close", des, self.Close, self)
    SetB(root, "mask", des, self.OnMask, self)
    SetB(root, "bgs/bg4", des, self.OnHelp, self)

    SetB(root, "hint/bg/yesBtn", des, self.OnYesBtn, self);
    SetB(root, "hint/bg/noBtn", des, self.OnNoBtn, self);

    self:InitActivState()
    self:InitData()
    self:InitActData()

    if (self.data and self.actData) or self.isOpen then
        self.luckBg:SetActive(true)
        self:UpLuckVal()
        self:UpWishCount()
        self:UpTokenCount()
        self:InitActTime()
        self:InitPrice()
        self:InitAwardItem1()
        self:InitAwardItem2()
        self:InitIcon()
        self:InitAction()
        self:UpAction()
        self:UpGoldLab()
        self:InitPanel2()
        self:SetLnsr("Add")
        self.data.notice = true;
        TimeLimitActivInfo.notice = true;
        self.hinttog.value = false;
        
    end
end

--设置监听
function My:SetLnsr(func)
    local mgr = FestivalActMgr
    mgr.eWishAward[func](mgr.eWishAward, self.RespWishAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
    RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpGoldLab, self)
    TimeLimitActivMgr.eUpWish[func](TimeLimitActivMgr.eUpWish, self.RespUpWish, self)
   
    
end

--道具添加
function My:OnAdd(action,dic)
	if action==10362 or action==10373  or (action==10361 and self:IsR(dic))then
        self.dic=dic
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--触发道具添加到许愿仓库时,判断是否为稀有物品
function My:IsR(awardList)
    local list = (self.isOpen) and self:GetCfgList(1, nil) or self.data.awardList1
    for i,v in ipairs(awardList) do
        for i1,v1 in ipairs(list) do
            local id = v.k
            local id1 = (self.isOpen) and v1.award[1].k or v1.id
            if id == id1 then
                return true
            end
        end
    end
    return false
end

--响应许愿奖励
function My:RespWishAward(count, awardList)
    local isRare = self:IsRare(awardList)
    self:UpWishCount()
    self:UpTokenCount()
    if(not isRare) then
        self:SetAnimPos(count, isRare)
        self:Begin()
    end
    self.panel2:UpScoreLab()
    for i,v in ipairs(self.panel2.itList) do
        v:SetBtnState()
    end
    self:UpLuckVal()
    self:UpAction()
end

--是否是稀有奖池里的道具
function My:IsRare(awardList)
    local list = (self.isOpen) and self:GetCfgList(1, nil) or self.data.awardList1
    for i,v in ipairs(awardList) do
        for i1,v1 in ipairs(list) do
            local id = (self.isOpen) and v or v.type_id
            local id1 = (self.isOpen) and v1.award[1].k or v1.id
            if id == id1 then
                return true
            end
        end
    end
    return false
end

--更新元宝数量显示
function My:UpGoldLab(ty)
    self.goldLab.text = RoleAssets.Gold
end

--初始化数据
function My:InitData()
    self.data = FestivalActInfo.wishData
end

--初始化活动数据
function My:InitActData()
    self.actData = FestivalActMgr:GetActInfo(FestivalActMgr.XYC)
end

--初始化奖励项1
function My:InitAwardItem1()
    if self.isOpen then
        local list = self:GetCfgList(1, true)
        self:SetAwardItem(self.awardItem1, list, self.cellList1, 1)
    else
        self:SetAwardItem(self.awardItem1, self.data.awardList1, self.cellList1, 1)
    end
end

--初始化奖励项2
function My:InitAwardItem2()
    if self.isOpen then
        local list = self:GetCfgList(0, true)
        self:SetAwardItem(self.awardItem2, list, self.cellList2, 2)
    else
        self:SetAwardItem(self.awardItem2, self.data.awardList2, self.cellList2, 2)
    end
end

--设置奖励项
function My:SetAwardItem(item, awardList, saveList, index)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(awardList) do
        local go = Instantiate(item)
        local tran = go.transform
        if v.isShow then go.name = v.isShow + 100 end
        Add(parent, tran)
        local cell = ObjPool.Get(UIItemCell)
        local scale = (index==1) and 1.2 or 1
        cell:InitLoadPool(tran, scale)
        local id = (self.isOpen) and v.award[1].k or v.id
        local num = (self.isOpen) and v.award[1].v or v.num
        cell:UpData(id, num)
        table.insert(saveList, cell)
    end
    item:SetActive(false)
end

--更新活动时间
function My:InitActTime()
    local eDate = (self.isOpen) and LivenessInfo.xsActivInfo["1028"].eTime or self.actData.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.timeLab then
        self.timeLab.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    if self.timeLab then
        self.timeLab.text = "活动结束"
    end
end

--初始化价格
function My:InitPrice()
    local cfg = self.curCfg
    local num1 = (self.isOpen) and cfg.Value1[1].value or self.data.unitPrice
    local num2 = (self.isOpen) and cfg.Value1[2].value or self.data.fullPrice
    self.unitPrice.text = string.format("许愿1次（%s元宝）", num1)
    self.fullPrice.text = string.format("许愿10次（%s元宝）", num2)
end

--初始化许愿次数
function My:UpWishCount()
    local val = (self.isOpen) and TimeLimitActivInfo.score or self.data.integral
    self.wishCount.text = val
end

--初始化许愿币数量
function My:UpTokenCount()
    local token = self:GetToken()
    self.tokenCount.text = token
end

--获取钥匙
function My:GetToken()
    local id = (self.isOpen) and self.curCfg.Value3 or self.data.itemId
    local token = ItemTool.GetNum(id)
    return token
end

--点击许愿一次
function My:OnBtn1()
    if (self:IsOpenHint() and self.clickBtn == 0) then
        self.clickBtn = 1;
        return
    end
    local token = self:GetToken()
    local num = (self.isOpen) and self.curCfg.Value1[1].value or self.data.unitPrice
    local total = token * num + RoleAssets.Gold
    if total < num then
        StoreMgr.JumpRechange()
        JumpMgr:InitJump(UIWish.Name)
        return
    end
    self.tween:ResetToBeginning()
    if self.isOpen then
        TimeLimitActivMgr:ReqWish(1)
    else
        FestivalActMgr:ReqWish(1)
    end
    
end

--点击许愿十次
function My:OnBtn2()
    if (self:IsOpenHint() and self.clickBtn == 0) then 
        self.clickBtn = 2;
        return
    end
    local cfg = self.curCfg
    local token = self:GetToken()
    local val1 = cfg.Value1[1].value
    local val2 = cfg.Value1[2].value
    local price1 = self.data.unitPrice
    local price2 = self.data.fullPrice
    local num = (self.isOpen) and val2 or price2
    local discount = (self.isOpen) and val2/val1 or price2/price1
    local total = token * (num/discount) + RoleAssets.Gold
    if total < num then
        StoreMgr.JumpRechange()
        JumpMgr:InitJump(UIWish.Name)
        return
    end
    self.tween:ResetToBeginning()
    if self.isOpen then
        TimeLimitActivMgr:ReqWish(10)
    else
        FestivalActMgr:ReqWish(10)
    end
  
end

--点击许愿仓库
function My:OnBtn3()
    self:InitPanel1()
end

--点击积分兑换
function My:OnBtn4()
    if self.panel2 then
        self.panel2:UpShow(true)
    end
end

--初始化许愿仓库
function My:InitPanel1()
    if self.panel1 == nil then
        self.panel1 = ObjPool.Get(UIWishPanel1)
        self.panel1:Init(self.panelTran1)
    end
    self.panel1:UpShow(true)
end

--初始化积分池
function My:InitPanel2()
    if self.panel2 == nil then
        self.panel2 = ObjPool.Get(UIWishPanel2)
        self.panel2:Init(self.panelTran2)
        local cfg = (self.isOpen) and WishAwardCfg or self.actData
        self.panel2:UpdateData(cfg, self.isOpen)
    end
end

--设置动画播放的位置
function My:SetAnimPos(index, isRare)
    local xPos = (index == 1) and 100 or 313
    local pos = self.spr.localPosition
    local str = (isRare) and "[F21919FF]稀有奖池" or "普通奖池"
    self.spr.localPosition = Vector3.New(xPos, pos.y, pos.z)
    self.lab.text = string.format("池子水波微微荡漾，送出了%s[-]道具，恭喜道长！", str)
end

--开始播放动画
function My:Begin()
    self.mask:SetActive(true)
	self.tween:PlayForward()
end

--点击遮罩
function My:OnMask()
    self.tween:ResetToBeginning()
    self.mask:SetActive(false)
end

--初始化许愿道具
function My:InitIcon()
    local id = (self.isOpen) and self.curCfg.Value3 or self.data.itemId
    if id == 0 then return end
    local cfg = ItemData[tostring(id)]
    if cfg == nil then return end
    self.texName = cfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--初始化默认红点
function My:InitAction()
    if self.isOpen then
        TimeLimitActivMgr:UpNorAction(4)
    else
        local mgr = FestivalActMgr
        mgr.InitAction = false
        mgr:UpWishAction()
    end
end

--更新红点
function My:UpAction()
    local token = (self.isOpen) and ItemTool.GetNum(self.curCfg.Value3) or ItemTool.GetNum(self.data.itemId)
    local state = (self.isOpen) and TimeLimitActivMgr:IsGetWishAward() or FestivalActMgr:IsGetWishAward()
    self.actionList[1]:SetActive(token>0)
    self.actionList[2]:SetActive(token>=10)
    self.actionList[4]:SetActive(state)
    self:UpBagAction()
end

--更新背包红点
function My:UpBagAction()
    local isShow = false
    for k,v in pairs(PropMgr.tb4Dic) do
        isShow = true
        break
    end
    self.actionList[3]:SetActive(isShow)
end

--点击帮助
function My:OnHelp()
    UIComTips:Show(InvestDesCfg["17"].des, Vector3(-235,210,0))
end

--提示界面确定按钮
function My:OnYesBtn()
    if (self.hinttog.value == true) then
        TimeLimitActivMgr:CloseHint(3);
    end
    if (self.clickBtn == 1) then
        self:OnBtn1();
    elseif (self.clickBtn == 2) then
        self:OnBtn2();
    end
    self.clickBtn = 0;
    self.hint:SetActive(false);
end

--弹出提示界面
--tog没勾上弹出
function My:IsOpenHint()
    if(self.hinttog.value == false) then
        if (self.isOpen) then
            if (TimeLimitActivInfo.preciousExist == false and TimeLimitActivInfo.notice == true) then
                self.hint:SetActive(true);
                return true;
            end
        else
            if (self.data.preciousExist ==false and self.data.notice == true) then
                self.hint:SetActive(true);  
                return true;
            end
        end
    end
    return false;
end

--提示界面取消按钮
function My:OnNoBtn()
    self.hint:SetActive(false);
    self.hinttog.value = false;
    self.clickBtn = 0;
end

--不再提醒复选框
function My:OnTog(go)
    
end

----------------------------------------------走本地配置

--初始化活动状态
function My:InitActivState()
    self.isOpen = LivenessInfo:IsOpen(1028)
end

--获取配置列表
function My:GetCfgList(index, isShow)
    local list = {}
    for i,v in ipairs(WishCfg) do
        if TimeLimitActivInfo.nowDay == nil or TimeLimitActivInfo.nowDay == 0 or TimeLimitActivInfo.nowDay == 1 then
            TimeLimitActivInfo.nowDay = v.nowDay;
        end
        if v.nowDay == TimeLimitActivInfo.nowDay then
            if v.isRare == index then
                if isShow and (index == 1) then
                    if v.isShow and v.isShow > 0 then
                        table.insert(list, v)
                    end
                else
                    table.insert(list, v)
                end
            end
        end
    end
    return list
end

--更新幸运值
function My:UpLuckVal()
    local cfg = self.curCfg
    local val = (self.isOpen) and TimeLimitActivInfo.luckVal or self.data.luckVal
    local str = string.format("%s/%s", val, cfg.Value2[2])
    self.slider.value = val / cfg.Value2[2]
    self.sliderLab.text = str
end

--响应更新许愿
function My:RespUpWish(count, awardList)
    local isRare = self:IsRare(awardList)
    if self.panel2 then
        self.panel2:UpScoreLab()
        self.panel2:UpBtnState()
    end
    self:UpWishCount()
    self:UpTokenCount()
    if(not isRare) then
        self:SetAnimPos(count, isRare)
        self:Begin()
    end
    self:UpLuckVal()
    self:UpAction()
end

--清理缓存
function My:Clear()
    self.dic = nil
    self.curCfg = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    ObjPool.Add(self.panel1)
    self.panel1 = nil
    ObjPool.Add(self.panel2)
    self.panel2 = nil
    TableTool.ClearListToPool(self.cellList1)
    TableTool.ClearListToPool(self.cellList2)
    AssetMgr:Unload(self.texName,false)
    self:SetLnsr("Remove")
end

return My