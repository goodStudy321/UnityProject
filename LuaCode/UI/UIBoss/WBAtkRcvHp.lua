WBAtkRcvHp = {Name = "WBAtkRcvHp"}
local My = WBAtkRcvHp;
My.RmdStr = "RcvHpCostReminder"

function My:Init(trans,TipTrans)
    local name = trans.name;
    local UCS = UITool.SetLsnrSelf;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    self.RcvHpPer = CG(UILabel,trans,"RcvHpPer");
    self.CostGold = CG(UILabel,trans,"CostGold");
    self.RcvCD = CG(UISprite,trans,"CD");
    UCS(trans.gameObject, self.OnRcvHp, self);

    self.RcvHpTip = TipTrans;
    self.Msg = CG(UILabel,TipTrans,"Tip/msg");
    self.RmdTgl = CG(UIToggle,TipTrans,"Tip/Reminder");
    EventDelegate.Set(self.RmdTgl.onChange, EventDelegate.Callback(self.OnReminder, self));
    self:ShowTip(false);
    self:RfData();
    UC(TipTrans,"Tip/bg/yesBtn",name,self.ClickYes,self);
    UC(TipTrans,"Tip/bg/noBtn",name,self.ClickNo,self);
end

--添加监听
function My:AddLsnr()
    WBRcvHp.eChgCount:Add(self.RfData,self);
end

--移除监听
function My:RmLnsr()
    WBRcvHp.eChgCount:Remove(self.RfData,self);
end

--刷新数据
function My:RfData()
    local rcvHpVal = string.format("%d%%",WBRcvHp.rcvHpPer);
    local costVal = tostring(WBRcvHp.costGold);
    self.RcvHpPer.text = rcvHpVal;
    self.CostGold.text = costVal;
end

--显示提示
function My:ShowTip(active)
    local trans = self.RcvHpTip;
    local isNull = LuaTool.IsNull(trans);
    if isNull == true then
        return;
    end
    if active == true then
        local msg = string.format("是否消耗%d元宝恢复%d%%的生命值",WBRcvHp.costGold,WBRcvHp.rcvHpPer);
        self.Msg.text = msg;
    end
    trans.gameObject:SetActive(active);
end

--点击确定
function My:ClickYes()
    WBRcvHp:ReqRcvHp();
    self:ShowTip(false);
end

--点击取消
function My:ClickNo()
    self:ShowTip(false);
end

--选择提醒
function My:OnReminder()
    local tgl = self.RmdTgl;
    local isNull = LuaTool.IsNull(tgl);
    if isNull == true then
        return;
    end
    local select = tgl.value;
    if select == true then
        local timeStamp = DateTool.GetTimestamp();
        timeStamp = tostring(timeStamp);
        PlayerPrefs.SetString(My.RmdStr,timeStamp);
    else
        PlayerPrefs.SetString(My.RmdStr,"0");
    end
end

--是否需要提醒
function My.IsNeedRmd()
    local hasKey = PlayerPrefs.HasKey(My.RmdStr);
    if hasKey == false then
        return true;
    end
    local timeStamp = PlayerPrefs.GetString(My.RmdStr);
    timeStamp = tonumber(timeStamp);
    if timeStamp == 0 then
        return true;
    end
    local isToday = DateTool.IsToday(timeStamp);
    if isToday == false then
        return true;
    end
    return false;
end

--回血点击
function My:OnRcvHp()
    local isCd = WBRcvHp.RcvRunning();
    if isCd == true then
        UITip.Log("CD中不能恢复血量");
        return;
    end
    local isNeedRmd = My.IsNeedRmd();
    if isNeedRmd == true then
        self:ShowTip(true);
    else
        WBRcvHp:ReqRcvHp();
    end
end

--更新CD
function My:UpdateCD()
    local cdSpr = self.RcvCD;
    local isNull = LuaTool.IsNull(cdSpr);
    if isNull == true then
        return;
    end
    local pro = WBRcvHp.GetRcvCD();
    if pro ~= 0 then
        pro = 1 - pro;
    end
    cdSpr.fillAmount = pro;
end

--更新
function My:Update()
    self:UpdateCD();
end