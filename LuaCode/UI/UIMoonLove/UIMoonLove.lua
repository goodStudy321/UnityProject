--[[
情缘对碰
]]
require("UI/UIMoonLove/MoonRecord")
require("UI/UIMoonLove/MoonScore")
require("UI/UIMoonLove/PlayerIt")

UIMoonLove=Super:New{Name="UIMoonLove"}
local My=UIMoonLove
local Players = UnityEngine.PlayerPrefs

My.desTab = {"天作之合","两小无猜","一见钟情","白头偕老"}
My.oneRewTab = {{1,1}} --大奖
My.twoRewTab = {{2,2},{3,3},{4,4}} --二等奖
My.threeRewTab = {{1,2},{1,3},{1,4},{2,1},{2,3},{2,4},{3,1},{3,2},{3,4}} --其他奖
--1  左       2: 右      3: 二等奖      4: 一等奖    5: 特大奖
My.playerEffTab = {"ui_tzzh_ju_z","ui_tzzh_ju_y","ui_tzzh_02_bz","ui_tzzh_01_bz","ui_tzzh_03_bz"}  -- 1 boy      2 girl
                 
function My:Init(go)
    self.go=go
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local U = UITool.SetBtnClick
    local UC = UITool.SetLsnrSelf
    local des = self.Name

    local wid = TF(trans,"widge",des)
    self.playerIt = TFC(wid,"itBg",des)
    self.playerIt:SetActive(false)
    self.buyBtn1 = TFC(wid,"buy1",des)
    self.buyBtn10 = TFC(wid,"buy2",des)

    self.OtherBtnGbj = TFC(wid,"OtherBtn",des)
    local buyBtn11 = TFC(wid,"OtherBtn/buy1",des)
    local buyBtn1010 = TFC(wid,"OtherBtn/buy2",des)
    self.buyLab11 = CG(UILabel,wid,"OtherBtn/buy1/lab",des)
    self.buyTex11 = CG(UITexture,wid,"OtherBtn/buy1/tex",des)
    self.btnGrid = CG(UIGrid,wid,"OtherBtn/buy2/grid",des)
    self.buyLab10101 = CG(UILabel,wid,"OtherBtn/buy2/grid/tex1/lab",des)
    self.buyLab10102 = CG(UILabel,wid,"OtherBtn/buy2/grid/tex2/lab",des)
    self.buyTex10101 = CG(UITexture,wid,"OtherBtn/buy2/grid/tex1",des)
    self.buyTex10102 = CG(UITexture,wid,"OtherBtn/buy2/grid/tex2",des)


    self.buyLab1 = CG(UILabel,wid,"buy1/lab",des)
    self.buyLab10 = CG(UILabel,wid,"buy2/lab",des)
    self.recBtn = TFC(wid,"recordBg",des)
    self.recordLab = CG(UILabel,wid,"recordBg/recLab",des)
    self.des1Lab = CG(UILabel,wid,"des1",des)
    self.des2Lab = CG(UILabel,wid,"des2",des)

    local kbg1 = TF(wid,"bg/kSp1",des)
    self.k1BoyPa = TF(kbg1,"b",des)
    self.k1GirlPa = TF(kbg1,"g",des)
    self.k1RewPa = TF(kbg1,"rePa",des)
    self.desResultLab = CG(UILabel,kbg1,"lab",des)

    local kbg2 = TF(wid,"bg/kSp2/scView",des)
    self.k2Grid = CG(UIGrid,kbg2,"grid",des)

    local kbg3 = TF(wid,"bg/kSp3/scView",des)
    self.k3Grid = CG(UIGrid,kbg3,"grid",des)

    local exBtn = TFC(wid,"rewardBtn",des)
    self.scoreRed = TFC(wid,"rewardBtn/red",des)
    self.scoreLab = CG(UILabel,wid,"scoreLab",des)
    self.remainLab = CG(UILabel,wid,"remainLab",des)
    local tipBtn = TFC(wid,"remainLab/tip",des)

    self.tog = CG(UIToggle,wid,"tog",des)
    self.boyGrid = CG(UIGrid,wid,"bGrid",des)
    self.girlGrid = CG(UIGrid,wid,"gGrid",des)

    self.boyRewPa = TF(wid,"bIt",des)
    self.girlRewPa = TF(wid,"gIt",des)

    self.moonExcha = TF(wid,"UIScore",des)
    self.moonRecods = TF(wid,"UIRankRec",des)

    self.fxPa = TF(wid,"fx",des)

    UC(self.buyBtn1,self.BuyOneTimes,self)
    UC(self.buyBtn10,self.BuyTenTimes,self)

    UC(buyBtn11,self.BuyOneTimes,self)
    UC(buyBtn1010,self.BuyTenTimes,self)

    UC(self.recBtn,self.OpenRecordsP,self)
    UC(exBtn,self.OpenExchangeP,self)
    UC(tipBtn,self.OpenTipsP,self)
    UC(self.tog.gameObject,self.OnToggleV,self)

    if not self.timer then 
        self.timer=ObjPool.Get(DateTimer) 
        self.timer.invlCb:Add(self.CountTime,self)
    end

    self.autimer = ObjPool.Get(iTimer)
    self.autimer.complete:Add(self.Complete, self)
    
    self:OpenCustom()
    self:SetEvent("Add")
    self.boyPlayerTab = {}
    self.girlPlayerTab = {}
    self.fxModTab = {}
    self.rewdDic = {}
    self.rewardSucTab = {}
    self.rewardDefTab = {}
    self.boyDifShow = nil
    self.girlDifShow = nil
    self.leftDifShow = nil
    self.rightDifShow = nil
    self.isFinishEff = true
    self.fxIndex = 0
    self.jumpIndex = 1
    self:RefreshPlayer(1,self.boyRewPa,self.k1BoyPa)
    self:RefreshPlayer(2,self.girlRewPa,self.k1GirlPa)
    self:LoadFx(1)
    self:LoadFx(2)
    self:LoadFx(3)
    self:LoadFx(4)
    self:LoadFx(5)
    self:SetLogs()
    self:RefSinRew()
    self:ShowRew(1)
    self:ShowRew(2)
    self:SetScore()
    self:SetTogV()
    self:SetPrice()
    self.uiBaseObj = UIMgr.Get(UIHeavenLove.Name)
    if not self.moonRecordsP then
        self.moonRecordsP = ObjPool.Get(MoonRecord)
        self.moonRecordsP:Init(self.moonRecods)
    end
end

function My:SetEvent(fn)
    MoonLoveMgr.eMoonReward[fn](MoonLoveMgr.eMoonReward,self.OnShowFx,self)
    MoonLoveMgr.eAddRecord[fn](MoonLoveMgr.eAddRecord,self.SetLogs,self)
    MoonLoveMgr.eMoonExchange[fn](MoonLoveMgr.eMoonExchange,self.SetScore,self)
    PropMgr.eUpdate[fn](PropMgr.eUpdate, self.SetPrice, self)
    -- UserMgr.eUpdateData[fn](UserMgr.eUpdateData,self.OnUpData,self)
end

function My:LoadTex(propId,tex2D)
    local del = ObjPool.Get(DelLoadTex)
    local texName = self:GetPropData(propId)
    texName = texName.icon
    del:Add(tex2D)
    del:SetFunc(self.SetIcon,self)
    AssetMgr:Load(texName,ObjHandler(del.Execute, del))
end

function My:SetIcon(tex,tex2D)
    if tex then
        tex2D.mainTexture = tex
    end
end

function My:GetPropData(propId)
    propId = tostring(propId)
    local itemCfg = ItemData[propId]
    return itemCfg
end

function My:SetPrice()
    local sinPrice = GlobalTemp["197"].Value2[1]
    local costId = GlobalTemp["197"].Value2[2] --月老紅線 -- 32016
    local getId = GlobalTemp["197"].Value2[3] --藍色妖姬 -- 32017
    local costNum = PropMgr.TypeIdByNum(costId)
    if costNum == 0 then
        self:ComShow(sinPrice,costId,getId)
    elseif costNum >= 1 and costNum < 10 then
        self:OneShow(sinPrice,costId,getId,costNum)
    elseif costNum >= 10 then
        self:TenShow(sinPrice,costId,getId,costNum)
    end
end

function My:ComShow(sinPrice,costId,getId)
    self.OtherBtnGbj:SetActive(false)
    self.buyBtn1:SetActive(true)
    self.buyBtn10:SetActive(true)
    local tenPrice = sinPrice * 10
    self.buyLab1.text = sinPrice .. "元宝"
    self.buyLab10.text = tenPrice .. "元宝"
    local str1 = ""
    local str2 = ""
    local costId = GlobalTemp["197"].Value2[2] --月老紅線
    local getId = GlobalTemp["197"].Value2[3] --藍色妖姬
    local cName = ItemData[tostring(costId)].name
    local gName = ItemData[tostring(getId)].name
    str1 = string.format("购买一束%s\n赠送1个%s","蓝色妖姬","月老红线")
    str2 = string.format("购买十束%s\n赠送10个%s","蓝色妖姬","月老红线")
    self.des1Lab.text = str1
    self.des2Lab.text = str2
end

function My:OneShow(sinPrice,costId,getId,costNum)
    self.OtherBtnGbj:SetActive(true)
    self.buyBtn1:SetActive(false)
    self.buyBtn10:SetActive(false)
    self:LoadTex(costId,self.buyTex11)
    self:LoadTex(costId,self.buyTex10101)
    self:LoadTex(2,self.buyTex10102)
    -- local tenPrice = sinPrice * 10
    self.buyTex10101.gameObject:SetActive(true)
    self.buyTex10102.gameObject:SetActive(true)

    self.buyLab11.text = costNum .. "/1"
    self.buyLab10101.text = costNum
    self.buyLab10102.text = (10 - costNum) * sinPrice .. "元宝"
    -- local str1 = ""
    -- local str2 = ""
    -- local costId = GlobalTemp["197"].Value2[2] --月老紅線
    -- local getId = GlobalTemp["197"].Value2[3] --藍色妖姬
    -- local cName = ItemData[tostring(costId)].name
    -- local gName = ItemData[tostring(getId)].name
    str1 = "进行一次配对"
    str2 = "进行十次配对"
    self.des1Lab.text = str1
    self.des2Lab.text = str2
    self.btnGrid:Reposition()
end

function My:TenShow(sinPrice,costId,getId,costNum)
    self.OtherBtnGbj:SetActive(true)
    self.buyBtn1:SetActive(false)
    self.buyBtn10:SetActive(false)
    self:LoadTex(costId,self.buyTex11)
    self:LoadTex(costId,self.buyTex10101)
    self:LoadTex(2,self.buyTex10102)
    -- local tenPrice = sinPrice * 10
    self.buyTex10101.gameObject:SetActive(true)
    self.buyTex10102.gameObject:SetActive(false)

    self.buyLab11.text = costNum .. "/1"
    self.buyLab10101.text = costNum .. "/10"
    self.buyLab10102.text = (10 - costNum) * sinPrice
    -- local str1 = ""
    -- local str2 = ""
    -- local costId = GlobalTemp["197"].Value2[2] --月老紅線
    -- local getId = GlobalTemp["197"].Value2[3] --藍色妖姬
    -- local cName = ItemData[tostring(costId)].name
    -- local gName = ItemData[tostring(getId)].name
    str1 = "进行一次配对"
    str2 = "进行十次配对"
    self.des1Lab.text = str1
    self.des2Lab.text = str2
    self.btnGrid:Reposition()
end


function My:UnLoadTex()
    local oneTex = self.buyTex11.mainTexture.name
    local twoTex = self.buyTex10101.mainTexture.name
    local thrTex = self.buyTex10102.mainTexture.name
    if oneTex then
        AssetMgr:Unload(oneTex, ".png", false)
    end
    if twoTex then
        AssetMgr:Unload(twoTex, ".png", false)
    end
    if thrTex then
        AssetMgr:Unload(thrTex, ".png", false)
    end
end

function My:SetScore()
    local score = MoonLoveMgr.moonInfoTab.curScore
    self.scoreLab.text = score
    local isRed = MoonLoveMgr:IsRed()
    if not LuaTool.IsNull(self.scoreRed) then
        self.scoreRed:SetActive(isRed)
    end
end

function My:RefSinRew()
    local rewTab = MoonLoveMgr:GetRew()
    local rewInfo = rewTab[3].rewTab[1]
    if self.sinRewItem == nil then
        local item = ObjPool.Get(UIItemCell)
        item:InitLoadPool(self.k1RewPa.transform)
        item:UpData(rewInfo.id,rewInfo.minLv)
        self.sinRewItem = item
    else
        self.sinRewItem:UpData(rewInfo.id,rewInfo.minLv)
    end
end

--index:1:成功       2 失败
function My:ShowRew(index)
    local rewTab = MoonLoveMgr:GetRew()
    local tab = nil
    local pa = nil
    if index == 1 then
        tab = rewTab[2].rewTab
        pa = self.k2Grid
        self:RefreshReward(index,tab,pa)
    elseif index == 2 then
        tab = rewTab[1].rewTab
        pa = self.k3Grid
        self:RefreshReward(index,tab,pa)
    end
end

function My:RefreshReward(index,reward,pa)
    local data = reward
    local len = #data
    local itemTab = nil
    if index == 1 then
        itemTab = self.rewardSucTab
    elseif index == 2 then
        itemTab = self.rewardDefTab
    end
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpData(data[i].id,data[i].minLv)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(pa.transform)
            item:UpData(data[i].id,data[i].minLv)
            if index == 1 then
                table.insert(self.rewardSucTab,item)
            elseif index == 2 then
                table.insert(self.rewardDefTab,item)
            end
        end
    end
    pa:Reposition()
end

function My:OnShowFx()
    if self.jumpIndex == 2 then
        self:SetScore()
        self:RefreshDes()
        -- self:ResultDes()
        -- self:RefSinRew()
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
        return
    end
    if self.uiBaseObj then
        self.uiBaseObj:Lock(true)
    end
    self.isFinishEff = false
    self.autoIndex = 0
    if not LuaTool.IsNull(self.fxModTab[1]) then
        self.fxModTab[1]:SetActive(true)
    end
    if not LuaTool.IsNull(self.fxModTab[2]) then
        self.fxModTab[2]:SetActive(true)
    end
	self:AutoTimer(0.5)
end

function My:Complete()
    self.autoIndex = self.autoIndex + 1
    local auIndex = self.autoIndex
    if auIndex == 1 then
        self:RefreshDes()
        self:AutoTimer(0.5)
    elseif auIndex == 2 then
        local type = self.finalType
        type = type + 2
        if not LuaTool.IsNull(self.fxModTab[type]) then
            self.fxModTab[type]:SetActive(true)
        end
        self:AutoTimer(0.5)
    elseif auIndex == 3 then
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
        -- self:SetLogs()
        self:SetScore()
        -- self:ResultDes()
        -- self:RefSinRew()
        self.fxModTab[1]:SetActive(false)
        self.fxModTab[2]:SetActive(false)
        self.fxModTab[3]:SetActive(false)
        self.fxModTab[4]:SetActive(false)
        self.fxModTab[5]:SetActive(false)
        self.isFinishEff = true
        if self.uiBaseObj then
            self.uiBaseObj:Lock(false)
        end
    end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.rewdDic)
	end
end

function My:AutoTimer(tm)
    local timer = self.autimer
    timer:Reset()
    timer:Start(tm)
end

function My:ResultDes()
    local rewTypeTab = MoonLoveMgr.moonInfoTab.rewTypeTab
    if rewTypeTab == nil or #rewTypeTab == 0 then
        return
    end
    local len = #rewTypeTab
    local desTab = {"配对失败","配对成功","完美情缘"}
    local type = 1
    if len == 1 then
        type = rewTypeTab[1]
    elseif len > 1 then
        type = rewTypeTab[len]
    end
    self.desResultLab.text = desTab[type]
end

function My:RefreshDes()
    TableTool.ClearDic(self.rewdDic)
    local rewTypeTab = MoonLoveMgr.moonInfoTab.rewTypeTab
    local rewListTab = MoonLoveMgr.moonInfoTab.rewListTab
    local rewTab = MoonLoveMgr:GetRew()
    local boyDifShow = self.boyDifShow
    local girlDifShow = self.girlDifShow
    local boyDicShow = self.leftDifShow
    local girlDicShow = self.rightDifShow
    local boy = 1
    local girl = 2
    local oneRew = self.oneRewTab
    local twoRew = self.twoRewTab
    local thrRew = self.threeRewTab
    local tab = nil
    local rewLsTab = nil
    self.finalType = rewTypeTab[1]
    local type = self.finalType --3:大奖      2：一等奖      1：二等奖
    if type == 3 then
        tab = oneRew
    elseif type == 2 then
        tab = twoRew
    elseif type == 1 then
        tab = thrRew
    end
    self:RefreshDisShow(tab,boyDifShow,girlDifShow,boyDicShow,girlDicShow)
    for i = 1,#rewListTab do
        rewLsTab = rewListTab[i]
        -- local cfg = rewTab[type]
        -- local rewTab = cfg.rewTab
        self:RefreshRew(rewLsTab)
    end
end

function My:RefreshRew(rewTab)
    local rewCfg = rewTab
    local tab = {}
    tab.k = rewCfg.type_id
    tab.v = rewCfg.num
    tab.b = rewCfg.bind
    self.rewdDic[#self.rewdDic+1] = tab
end

function My:RefreshDisShow(tab,boyDifShow,girlDifShow,boyDicShow,girlDicShow)
    local boyDifShow = self.boyDifShow
    local girlDifShow = self.girlDifShow
    local len = #tab
    local num = math.random(1,len)
    boyDifShow:RefreshData(1,tab[num][1])
    girlDifShow:RefreshData(2,tab[num][2])
    -- boyDicShow:RefreshData(1,tab[num][1])
    -- girlDicShow:RefreshData(2,tab[num][2])
end

function My:LoadFx(index)
    local fxName = self.playerEffTab[index]
    if fxName == nil then
        return
    end
    if self.fxModTab[index] == nil then
        LoadPrefab(fxName, GbjHandler(self.SetFxGo, self))
    end
end

function My:SetFxGo(go)
    self.fxIndex = self.fxIndex + 1
    local index = self.fxIndex
    local tran = go.transform
    self.fxModTab[index] = go
    tran.parent = self.fxPa
    local pos = nil
    if index == 1 or index == 2 then
        pos = Vector3.New(-87,0,0)
    else
        pos = Vector3.New(160,73,0)
    end
	tran.localScale = Vector3.one
	tran.localPosition = pos
	go:SetActive(false)
end

function My:UnLoadFx()
    local p, c= self.fxPa
	local count = p.childCount - 1
	for i=0, count do
		c = p:GetChild(i)
		AssetMgr:Unload(c.name, ".prefab", false)
	end
end

--index:1 boy      2 girl
function My:RefreshPlayer(index,pa,dicPa)
    local itemTab = nil
    local go = self.playerIt
    local tranPa = nil
    local difShow = nil
    local dicDifShow = nil
    if index == 1 then
        itemTab = self.boyPlayerTab
        tranPa = self.boyGrid
        difShow = ObjPool.Get(PlayerIt)
        difShow:InitLoadIt(go,pa)
        difShow:RefreshData(index,1)
        dicDifShow = ObjPool.Get(PlayerIt)
        dicDifShow:InitLoadIt(go,dicPa)
        dicDifShow:RefreshData(index,1)
        self.boyDifShow = difShow
        self.leftDifShow = dicDifShow
        self:ShowPlayers(index,go,tranPa,itemTab)
    elseif index == 2 then
        itemTab = self.girlPlayerTab
        tranPa = self.girlGrid
        difShow = ObjPool.Get(PlayerIt)
        difShow:InitLoadIt(go,pa)
        difShow:RefreshData(index,1)
        dicDifShow = ObjPool.Get(PlayerIt)
        dicDifShow:InitLoadIt(go,dicPa)
        dicDifShow:RefreshData(index,1)
        self.girlDifShow = difShow
        self.rightDifShow = dicDifShow
        self:ShowPlayers(index,go,tranPa,itemTab)
    end
    self.boyGrid:Reposition()
    self.girlGrid:Reposition()
end

function My:ShowPlayers(index,go,tranPa,itemTab)
    local data = self.desTab
    local len = #data
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:RefreshData(index,i)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local item = ObjPool.Get(PlayerIt)
            item:InitLoadIt(go,tranPa)
            item:RefreshData(index,i)
            if index == 1 then
                table.insert(self.boyPlayerTab,item)
            elseif index == 2 then
                table.insert(self.girlPlayerTab,item)
            end
        end
    end
end

function My:SetLogs()
    local typeDesTab = {"配对失败","配对成功","完美情缘"}  
    local tab = MoonLoveMgr.moonInfoTab.addRecordTab
    if tab == nil then
        tab = MoonLoveMgr.moonInfoTab.recordTab
    end
    if tab == nil or #tab == 0 then
        self.recBtn.gameObject:SetActive(false)
        return
    end
    if not LuaTool.IsNull(self.recBtn) then
        self.recBtn.gameObject:SetActive(true)
    end
    -- local finRecInfo = tab[#tab]
    local finRecInfo = tab[1]
    local name = finRecInfo.role_name --角色名字
    local type = finRecInfo.reward_type --奖励类型
    local rewId = finRecInfo.type_id_list[1] --道具ID
    -- local tn , qtColor, itCfg = nil, nil, nil
    local sb = ObjPool.Get(StrBuffer)
    -- local LabColor = UIMisc.LabColor
    sb:Apd("[F4DDBDFF]")
    itCfg = ItemData[tostring(rewId)]
    -- qtColor = LabColor(itCfg.quality)
    sb:Apd("恭喜[00FF00]["):Apd(name):Apd("[-]]"):Apd("[E461DEFF]["):Apd(typeDesTab[type])
    sb:Apd("][-]\n获得道具"):Apd("[E461DEFF]["):Apd(itCfg.name):Apd("][-]")
    self.recordLab.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:CountTime()
    local times = self.timer:GetRestTime()
    times = math.ceil(times)
    local str = ""
    if times <= 1 then
        local active = UIMgr.GetActive(UIHeavenLove.Name)
        local ui = UIMgr.Get(UIHeavenLove.Name)
        if ui and active ~= -1 then ui:Close() end
        -- str = "活动已结束"
    else
        str = self.timer.remain
    end
    self.remainLab.text=str
end

function My:OpenCustom( ... )
    local info = NewActivMgr:GetActivInfo(2012)
    if info then
        local time = info.endTime-DateTool.GetServerTimeSecondNow()
        self.remainLab.text=DateTool.FmtSec(time)
        self.timer:Stop()
        self.timer.seconds=time
        self.timer:Start()
    end
end

--兑换一次
function My:BuyOneTimes()
    local isOpen = NewActivMgr:ActivIsOpen(2012)
    if not isOpen then
        UITip.Error("活动已结束")
        return
    end
    local isFinish = self.isFinishEff
    local sinPrice = GlobalTemp["197"].Value2[1]
    local gole = RoleAssets.Gold
    local propId = GlobalTemp["197"].Value2[2]
    local propNum = PropMgr.TypeIdByNum(propId)
    if gole < sinPrice and propNum < 1 then
        self:GoPay()
        return
    end
    if isFinish == true then
        MoonLoveMgr:ReqMoonTimes(1)
    end
end

--兑换十次
function My:BuyTenTimes()
    local isOpen = NewActivMgr:ActivIsOpen(2012)
    if not isOpen then
        UITip.Error("活动已结束")
        return
    end
    local isFinish = self.isFinishEff
    local sinPrice = GlobalTemp["197"].Value2[1]
    local tenPrice = sinPrice * 10
    local gole = RoleAssets.Gold
    local propId = GlobalTemp["197"].Value2[2]
    local propNum = PropMgr.TypeIdByNum(propId)
    local priceNum = math.floor(gole/sinPrice)
    if propNum == nil then propNum = 0 end
    priceNum = priceNum + propNum
    if priceNum < 10 then
        self:GoPay()
        return
    end
    if isFinish == true then
        MoonLoveMgr:ReqMoonTimes(10)
    end
end

function My:GoPay()
    local showStr = "元宝不足，前往充值?";
    MsgBox.ShowYesNo(showStr, self.GotoPay, self);
end

function My:GotoPay()
	VIPMgr.OpenVIP(1);
end

--打开记录
function My:OpenRecordsP()
    -- if not self.moonRecordsP then
    --     self.moonRecordsP = ObjPool.Get(MoonRecord)
    --     self.moonRecordsP:Init(self.moonRecods)
    -- end
    self.moonRecordsP:Open()
end

--打开兑换礼盒
function My:OpenExchangeP()
    if not self.moonExchangeP then
        self.moonExchangeP = ObjPool.Get(MoonScore)
        self.moonExchangeP:Init(self.moonExcha)
    end
    self.moonExchangeP:Open()
end

--打开提示面板
function My:OpenTipsP()
    local desInfo = InvestDesCfg["2020"]
    local str = desInfo.des
    UIComTips:Show(str, Vector3(-223,-31,0),nil,nil,nil,700,UIWidget.Pivot.TopLeft)
end

--是否跳过动画
function My:OnToggleV()
    local val = self.tog.value
    local jumpIndex = 1
    if val == true then
        jumpIndex = 2
    end
    Players.SetInt("MoonLove", jumpIndex)
    self.jumpIndex = jumpIndex
end

function My:SetTogV()
    if Players.HasKey("MoonLove") then
        local togVal = Players.GetInt("MoonLove")
        if togVal == 2 then
            self.tog.value = true
        else
            self.tog.value = false
        end
        self.jumpIndex = togVal
    end
end

function My:EndTimer()
	if self.autimer then
		self.autimer:AutoToPool()
	end
	self.autimer = nil
end

function My:Open( ... )
    local isRed = MoonLoveMgr:IsRed()
    if not isRed then
        MoonLoveMgr.eRed(false,6)
    end
    self.go:SetActive(true)
end

function My:Close( ... )
    self.go:SetActive(false)
end

function My:Dispose()
    self:SetEvent("Remove")
    self.fxIndex = 0
    if self.timer then 
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.moonExchangeP then 
        ObjPool.Add(self.moonExchangeP) 
        self.moonExchangeP = nil 
    end
    if self.moonRecordsP then
        ObjPool.Add(self.moonRecordsP)
        self.moonRecordsP = nil
    end
    self:EndTimer()
    if self.sinRewItem then
        self.sinRewItem:DestroyGo()
        ObjPool.Add(self.sinRewItem)
        self.sinRewItem = nil
    end
    TableTool.ClearListToPool(self.boyPlayerTab)
    TableTool.ClearListToPool(self.girlPlayerTab)
    TableTool.ClearListToPool(self.rewardSucTab)
    TableTool.ClearListToPool(self.rewardDefTab)
    TableTool.ClearDic(self.rewdDic)
    ObjPool.Add(self.boyDifShow)
    ObjPool.Add(self.girlDifShow)
    ObjPool.Add(self.leftDifShow)
    ObjPool.Add(self.rightDifShow)
    self:UnLoadTex()
    self.boyDifShow = nil
    self.girlDifShow = nil
    self.leftDifShow = nil
    self.rightDifShow = nil
    self.jumpIndex = 1
    self.isFinishEff = true
    self.uiBaseObj = nil
    self:UnLoadFx()
end