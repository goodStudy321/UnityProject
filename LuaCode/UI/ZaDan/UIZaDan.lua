--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/9/9 下午2:37:45
--=============================================================================


UIZaDan = UIBase:New{ Name = "UIZaDan" }
require("UI/Cmn/UIItemsTable")
require("UI/ZaDan/UIZaDanIt")
require("Tool/SimpleGoPool")

local My = UIZaDan
My.record = require("UI/ZaDan/UIZaDanRecord")
My.addUp = require("UI/ZaDan/UIZaDanAddUp")

--砸蛋特效时间
My.zaFxTm = 1.7

----BEG PUBLIC


----END PUBLIC
My.deses = {"金蛋", "彩蛋", "龙蛋"}

My.colors = {"[B03DF2]", "[F9AB47]", "[F21919]"}

function My:InitCustom()
    self:SetLsnr("Add")


    local root, des = self.root, self.Name
    local USBC ,CG= UITool.SetBtnClick,ComTool.Get
    local TF,TFC= TransTool.Find, TransTool.FindChild
    local bg = TF(root, "bg", des)
    self.allConGoldLbl = CG(UILabel, bg, "allBtn/des", des)
    self.refreshGoldLbl = CG(UILabel, bg, "refreshBtn/des", des)
    self.refreshTween =  CG(UIPlayTween, bg, "refreshFx", des)
    self.hammerLbl =  CG(UILabel, bg, "cur/hammar", des)
    self.timerLbl =  CG(UILabel, bg, "timer", des)

    self.timer = ObjPool.Get(DateTimer)
    self.timer.invlCb:Add(self.UpdateTimer, self)
    self.timer.complete:Add(self.Close, self)

    self.refreshTimer = ObjPool.Get(iTimer)
    self.refreshTimer.complete:Add(self.ReqRefresh, self)

    self.zaAllTimer = ObjPool.Get(iTimer)
    self.zaAllTimer.complete:Add(self.ReqZaAll, self)

    local oneConColdLbl = CG(UILabel, bg, "one/gold", des)
    local oonConHarmLbl = CG(UILabel, bg, "one/hammar", des)
    oneConColdLbl.text = tostring(ZaDanMgr:GetOneConGold())
    oonConHarmLbl.text = tostring(ZaDanMgr:GetOneConHarm())
    self:SetRefreshGoldLbl()


    if(self.awards == nil ) then self.awards = UIItemsTable:New() end
    local uiTbl =  CG(UITable, bg, "awardItems", des)
    local cfg = ZaDanMgr.cfg
    self.awards:Init(uiTbl)
    self.awards:Refresh(cfg.Value1,"id", nil, "value", nil, 0.62)

    USBC(bg, "closeSp/btn", des, self.Close, self)
    USBC(bg, "recordBtn", des, self.OnClickRecordBtn, self)
    USBC(bg, "allBtn", des, self.OnClickAllBtn, self)
    USBC(bg, "tipBtn", des, self.OnClickTipBtn, self)
    USBC(bg, "refreshBtn", des, self.OnClickRefreshBtn, self)

    local rtran = TF(bg, "record", des)
    self.record:Init(rtran)
    self.record:Close()
    
    local atran = TF(bg, "addUp", des)
    self.addUp:Init(atran)

    self.areaTran = TF(bg, "area", des)

    if (self.pool == nil) then self.pool = ObjPool.Get(SimpleGoPool) end
    local poolRoot = TF(self.areaTran, "pool", des)
    self.pool:Init(poolRoot)

    self.danMod = TFC(self.areaTran, "it", des)
    self.danMod:SetActive(false)
    self:SetDanIts()
    self:SetAllConGoldLbl()

    self.flagGo = TFC(bg, "left/flag", des)
    self:SetFlagActive(ZaDanMgr.flag.red)

    self:SetAddUpState()
end

--设置蛋列表
function My:SetDanIts()
    if self.danIts == nil then self.danIts = {} end
    local p , mod, its = self.areaTran, self.danMod, self.danIts
    local go, it, c, itran = nil, nil ,nil, nil 
    local TF, zero, one= TransTool.Find, Vector3.zero, Vector3.one
    local infos = ZaDanMgr.infos
    for i=1, 8 do
        go = Instantiate(mod)
        c = go.transform
        itran = TF(p, tostring(i), self.Name)
        c.parent = itran
        c.localPosition = zero
        c.localScale = one
        go:SetActive(true)
        it = ObjPool.Get(UIZaDanIt)
        it:Init(c, infos[i], self)
        its[i] = it
    end
end

--重设蛋列表
function My:ResetDanIts()
    local its = self.danIts
    for i, v in ipairs(its) do
        v:Refresh()
    end
end

--list:p_egg列表
function My:ResetDanByMsg(list)
    if list == nil then return end
    local its = self.danIts
    for i, v in ipairs(list) do
        local id = v.id
        its[id]:Refresh()
    end
end

function My:StartTimer()
    local endTm = ZaDanMgr:GetEndTime()
    if endTm > 0 then 
        local sec =  endTm - DateTool.GetServerTimeSecondNow()
        self.timer.seconds = sec
        self.timer:Start() 
    end
end

function My:EndTimer()
    if self.timer then
        self.timer:AutoToPool()
    end
    self.timer = nil
end

function My:UpdateTimer()
    self.timerLbl.text = self.timer.remain
end

function My:EndRefreshTimer()
    if self.refreshTimer then
        self.refreshTimer:AutoToPool()
    end
    self.refreshTimer = nil
end

--砸所有蛋
function My:ReqZaAll()
    ZaDanMgr:DirectReqZaDan(0)
end

function My:OnClickAllBtn()
    local count = ZaDanMgr:GetNotOpenCount()
    if count < 1 then
        UITip.Log("没有可以砸的蛋")
        return 
    end
    local oneCon = ZaDanMgr:GetOneConHarm()
    local itCnt = ItemTool.GetNum(self.hammerID)
    local totalCon = oneCon * count
    if itCnt < totalCon then
        local totalGold = ZaDanMgr:GetOneConGold() * count
        if RoleAssets.Gold < totalGold then
            UITip.Error("道具和元宝不足")
            return
        end
    end
    local its , infos = self.danIts, ZaDanMgr.infos
    for i, v in ipairs(infos) do
        if v:CanZa() then
            its[i]:BegZaFx()
        end
    end
    self:Lock(true)
    self.zaAllTimer.seconds = self.zaFxTm
    self.zaAllTimer:Start()
end

function My:EndZaAllTimer()
    if self.zaAllTimer then
        self.zaAllTimer:AutoToPool()
    end
    self.zaAllTimer = nil
end

function My:OnClickTipBtn()
    local str = InvestDesCfg["2010"].des
    UIComTips:Show(str)
end

function My:OnClickRecordBtn()
    self.record:Open()
end

--请求刷新
function My:OnClickRefreshBtn()
    if not ZaDanMgr.canRefresh then
        local count = ZaDanMgr:GetNotOpenCount()
        if count > 0 then
            local total = ZaDanMgr:GetRefreshGold() * count
            if RoleAssets.Gold < count then
                UITip.Error("元宝不足")
                return
            end
        end
    end
    self:Lock(true)
    self.refreshTween:Play(true)
    self.refreshTimer:Start(0.8)
end

function My:ReqRefresh()
    if (not ZaDanMgr:ReqRefresh()) then
        self:Lock(false)
    end
    --self:RespRefresh()
end


function My:OpenCustom()
    self:SetHammarLbl()
    self:StartTimer()
    self:UpdateTimer()
end


function My:SetAllConGoldLbl()
    local count = ZaDanMgr:GetNotOpenCount()
    local total = ZaDanMgr:GetAllConGold(count)
    local str = "全部砸开\n " .. total .. "元宝"
    self.allConGoldLbl.text = str
end

function My:SetRefreshGoldLbl()
    local str = nil
    if ZaDanMgr.canRefresh then
        str = "免费刷新"
    else
        local count = ZaDanMgr:GetNotOpenCount()
        if count == 0 then
            str = "免费刷新"
        else
            local total = ZaDanMgr:GetRefreshGold() * count
            str = "刷 新\n " .. total .. "元宝"
        end
    end
    self.refreshGoldLbl.text = str
end

function My:SetHammarLbl()
    local num = ItemTool.GetNum(ZaDanMgr.hammerID)
    self.hammerLbl.text = tostring(num)
end

function My:SetAddUpState()
    self.addUp:SetStateByTime(ZaDanMgr.times, ZaDanMgr.maxTime)
end

function My:RespZaDan(msg)
    self:Lock(false)
    if msg.err_code < 1 then
        self:SetAllConGoldLbl()
        self:SetRefreshGoldLbl()
        self:ResetDanByMsg(msg.eggs)
        self:SetAddUpState()
    end
end

function My:RespRefresh(msg)
    self:Lock(false)
    if msg.err_code < 1 then
        self:ResetDanIts()
        self:SetAllConGoldLbl()
        self:SetRefreshGoldLbl()
    end
    self.refreshTween:Play(false)
    --TODO
end


function My:RespRecord(highLogs, normLogs)
    self.record:SetRecord(highLogs, normLogs)
end

function My:RespRefreshFree()
    self:SetRefreshGoldLbl()
end

function My:RespGet(msg)
    if msg.err_code > 0 then return end
    self.addUp:RespGet(msg)
end

function My:RespSysState(actInfo)
    if not ZaDanMgr:IsOpen() then
        self:Close()
    end
end

function My:SetFlagActive(at)
    self.flagGo:SetActive(at)
end

function My:SetLsnr(fn)
    local Rm = ZaDanMgr
    Rm.eZaDan[fn](Rm.eZaDan, self.RespZaDan, self)
    Rm.eRefresh[fn](Rm.eRefresh, self.RespRefresh, self)
    Rm.eRecord[fn](Rm.eRecord, self.RespRecord, self)
    Rm.eRefreshFree[fn](Rm.eRefreshFree, self.RespRefreshFree, self)
    Rm.eRespGet[fn](Rm.eRespGet, self.RespGet, self)
    Rm.eSysState[fn](Rm.eSysState, self.RespSysState, self)
    Rm.flag.eChange[fn](Rm.flag.eChange ,self.SetFlagActive, self)
    PropMgr.eUpdate[fn](PropMgr.eUpdate, self.SetHammarLbl, self)
end

function My:GetDanDes(ty)
    local des = self.deses[ty] or ("无类型:" .. ty)
    return des
end

function My:CloseCustom()
    
end


function My:DisposeCustom()
    ListTool.ClearToPool(self.danIts)
    self.awards:Dispose()
    self.record:Dispose()
    self.addUp:Dispose()
    self:SetLsnr("Remove")
    self:EndTimer()
    self:EndZaAllTimer()
    self:EndRefreshTimer()
end


return My