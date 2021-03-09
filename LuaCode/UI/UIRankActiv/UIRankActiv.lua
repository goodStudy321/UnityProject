--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:30:00
 	descrition 	:开服冲榜界面
--]]

UIRankActiv = UIBase:New{Name = "UIRankActiv"}

local My = UIRankActiv

require("UI/UIRankActiv/UIRankMenu")
require("UI/UIRankActiv/UIRankActivPop")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    local menuTran = Find(root, "RankMenu", des)
    local rankTran = Find(root, "RankAward", des)
    self.timeLab = CG(UILabel, root, "RankMenu/module1/noticeBg/lab")
    self.id = 0
    self.isEnd = false
    self.labList = {}
    self.labList1 = {}
    self.markList = {}
    self.redDotList = {}
    
    SetB(root, "Close", des, self.CloseBtn, self)
    SetB(root, "RankMenu/rankBtn", des, self.OnRankClick, self)

    self:InitBtn(root, Find, FindC, SetB, des)
    self:InitModule(menuTran, rankTran)
    self:CreateTimer()
    -- self:OnBtn1()
    self:InitTab()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = RankActivMgr
    mgr.eActivInfo[func](mgr.eActivInfo, self.RespActivInfo, self)
    mgr.eGetAward[func](mgr.eGetAward, self.RespGetAward, self)
    mgr.eBuyItem[func](mgr.eBuyItem, self.RespBuyItem, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:OpenTabByIdx(t1, t2, t3, t4)
	
end

function My:CloseBtn()
    self:Close()
    JumpMgr.eOpenJump()
end

--道具添加
function My:OnAdd(action,dic)
	if action==10021 then		
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

--响应开服活动信息
function My:RespActivInfo(id, state, rank, cond, rankState, err)
    if err > 0 then
        local cfg = RankActivCfg[id]
        if cfg then
            local str = string.format("开服第%s天开启", cfg.day)
            UITip.Log(str)
        end
        return
    end
    self.id = id
    self:UpTimeLab(id)
    self:SetBtnState(id)
    self.rankMenu.module1:UpData(id, state, rankState, rank)
    self.rankMenu.module2:UpData(id, rank, cond, state)
    self:UpBtnRedDot()
end

--响应获取奖励
function My:RespGetAward()
    self:ReqGetData(self.id)
    -- self:UpBtnRedDot()
end

--响应购买道具
function My:RespBuyItem()
    local info = self.rankMenu.module2
    for i,v in ipairs(info.itList) do
        v:UpMaxCount()
    end
end

--更新某项活动红点
function My:UpBtnRedDot()
    local dic = RankActivInfo.actionDoc
    for i,v in ipairs(self.redDotList) do
        local key = tostring(i)
        local val = dic[key]
        if val and val == true then
            v:SetActive(val)
        else
            v:SetActive(false)
        end
    end
end

--请求获取数据
function My:ReqGetData(id)
    RankActivMgr:ReqRankActiv(id)
end

--初始化时间文本
function My:UpTimeLab(id)
    local info = LivenessInfo.xsActivInfo["1007"]
    if info == nil then
        iTrace.Error("SJ", "该活动尚未开启")
        self.timeLab.text = "【活动倒计时】活动未开启"
        return
    end
    local timer = self.timer
    local eTime=info.eTime
    local lerp=eTime-DateTool.GetServerTimeSecondNow()
    if lerp>0 then
        timer:Stop()
        timer.seconds = lerp
        timer:Start()
        self:InvCountDown()
        self.isEnd = false
    else
        timer:Stop()
        self.timeLab.text = "【活动倒计时】活动已结束"
        self.isEnd = true
    end
end

-- --初始化时间文本
-- function My:UpTimeLab(id)
--     local info = LivenessInfo.xsActivInfo["1007"]
--     if info == nil then
--         iTrace.Error("SJ", "该活动尚未开启")
--         self.timeLab.text = "【活动倒计时】活动未开启"
--         return
--     end
--     local now = TimeTool.GetServerTimeNow()*0.001--当前的时间
--     local index = DateTool.GetDay(now - info.sTime) + 1--当前的天数索引
--     local cfg = RankActivCfg[id]
--     local timer = self.timer
--     local eDay = cfg.rankTime[1]
--     local sDay = cfg.day
--     if index <= eDay then
--         local allDay = (eDay - sDay) + 1--当前活动的总天数
--         local temp1 = allDay*24*60*60
--         local temp2 = 24 - cfg.rankTime[2]
--         local temp3 = (index-1)*24*60*60
--         local allSec = temp3 + temp1-(temp2*60*60)--已经过天数的总秒数 + 当前活动的总秒数
--         local seced = (index==2) and now - info.sTime + temp3 or now - info.sTime--已经过的秒数
--         local rSec = allSec - seced--当前活动剩余的秒数
--         timer:Stop()
--         timer.seconds = rSec
--         timer:Start()
--         self:InvCountDown()
--         self.isEnd = false
--     else
--         timer:Stop()
--         self.timeLab.text = "【活动倒计时】活动已结束"
--         self.isEnd = true
--     end
-- end

--初始化按钮
function My:InitBtn(root, Find, FindC, SetB, des)
    local CG = ComTool.Get
    for i=1, 7 do   --新增五行排行
        local func = "OnBtn"..i
        local path = "ActivModule/btn"..i
        local btn = Find(root, path, des)
        local redDot = FindC(root, path.."/redDot", des)
        local lab = FindC(root, path.."/Label", des)
        local lab1 = FindC(root, path.."/Label1", des)
        local mark = FindC(root, path.."/Mark", des)
      --  print("                                 ".."第"..i.."个按钮初始化")
        table.insert(self.redDotList, redDot)
        table.insert(self.labList, lab)
        table.insert(self.labList1, lab1)
        table.insert(self.markList, mark)

        SetB(root, path, des, self[func], self)
    end
end

--设置按钮状态
function My:SetBtnState(index)
    for i,v in ipairs(self.labList) do
        if i == index then
            self:SetBtnListState(i, false)
         --   print("                                 ".."第"..i.."个按钮false") --五行为第七个按钮
        else
            self:SetBtnListState(i, true)
         --   print("                                 ".."第"..i.."个按钮true")
        end
    end
end

--设置按钮列表状态
function My:SetBtnListState(index, state)
    self.labList[index]:SetActive(state)
    self.labList1[index]:SetActive(not state)
    self.markList[index]:SetActive(not state)
end

--打开分页
function My:OpenTab(index)
    local isOpen = UITabMgr.Pattern3(ActivityMgr.KFCB)
    if isOpen == false then return end
    self.index = index
    UIMgr.Open(UIRankActiv.Name)
end

--初始化分页
function My:InitTab()
    local funcName = (self.index) and "OnBtn"..self.index or "OnBtn7"
    if self==nil or self[funcName]==nil then return end--添加保护判断
    self[funcName](self)
end

--点击冲级达人
function My:OnBtn1()
    self:ReqGetData(1)
end

--点击坐骑进阶
function My:OnBtn2()
    self:ReqGetData(2)
end

--点击寻宠达人
function My:OnBtn3()
    self:ReqGetData(3)
end

--点击今日充值
function My:OnBtn4()
    self:ReqGetData(4)
end

--点击宝石镶嵌
function My:OnBtn5()
    self:ReqGetData(5)
end

--点击战力排行
function My:OnBtn6()
    self:ReqGetData(6)
end

--点击五行排行
function My:OnBtn7()
    self:ReqGetData(7)
--    print("                                 ".."第7个按钮响应") --说明执行了该方法
end

--点击排行榜按钮
function My:OnRankClick()
    UIRankActiv.rankPop:UpShow(true)
    RankActivMgr:ReqRankInfo(self.id)
end

--初始化模块
function My:InitModule(menuTran, rankTran)
    self.rankMenu = ObjPool.Get(UIRankMenu)
    self.rankMenu:Init(menuTran)
    self.rankPop = ObjPool.Get(UIRankActivPop)
    self.rankPop:Init(rankTran)
end

--创建计时器
function My:CreateTimer()
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    if self.timeLab then
        self.timeLab.text = "【活动倒计时】"..self.timer.remain
    end
end

--结束倒计时
function My:EndCountDown()
	self.timeLab.text = "【活动倒计时】活动已结束"
end

--清理计时器
function My:ClearTimer()
    if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self.dic = nil
    self.id = 0
    self.isEnd = false
end
    
--释放资源
function My:DisposeCustom()
    self:Clear()
    self:ClearTimer()
    self:SetLnsr("Remove")
    ObjPool.Add(self.rankMenu)
    self.rankMenu = nil
    ObjPool.Add(self.rankPop)
    self.rankPop = nil
end

return My