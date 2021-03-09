UITimeBuy=Super:New{Name="UITimeBuy"};
local My = UITimeBuy;
local CBM = CloudBuyMgr;
My.Bigls1=nil;
My.samList={};
My.recList={};
--是否在无限购买时候
My.maxBool=false;
--最新限制
My.curMaxBool=My.maxBool;
--全服信息格子集合
My.rclst = {};
function My:Init(root)
    self.glInfo=GlobalTemp["59"];
    local tip = self.Name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local ED = EventDelegate
    local EC, ES = ED.Callback, ED.Set
    --节点
    local info = TF(root,"info",tip);
    local btn = TF(root,"btn",tip);
    local sv = TF(root,"sv",tip);
    local silder = TF(root,"slide",tip);
    -- self.des = TF(root,"decShow",tip)

    --label类
    local lb = UILabel;
    self.residue=CG(lb,info,"residue",tip);
    self.timeDn=CG(lb,info,"timeDn",tip);
    self.need=CG(lb,info,"need",tip);
    self.bought=CG(lb,info,"bought",tip);
    --self.infinite=CG(lb,info,"infinite",tip);
    self.price=CG(lb,btn,"buyOnce/price",tip);
    self.priceTen=CG(lb,btn,"buyTenth/price",tip);
    -- self.desLb = CG(lb,self.des,"msg",tip)

    --按钮
    UC(btn, "buyOnce", self.Name, self.BuyOne, self);
    UC(btn, "buyTenth", self.Name, self.BuyTen, self);
    UC(btn, "say", self.Name, self.howPlay, self);
    UC(btn, "big", self.Name, self.OpenBigRCD, self);
    -- UC(root, "decShow", self.Name, self.CloseDec, self);
    --滑条
    self.silder = CG(UISlider, silder, "showless", des)
    --奖励记录显示
    -- self.record=CG(UIGrid,sv,"svRecord/Grid",tip);
    self.cbrcdname=CG(lb,sv,"svRecord/Grid/cbrcdname",tip).gameObject;
    soonTool.setPerfab(self.cbrcdname,"cbrcdname");
    self.samRwd=CG(UIGrid,sv,"svRwd/Grid",tip);
    self.bigRwd=TF(sv,"bigRwd",tip);
    self:Lsnr("Add");
    self:show();
end

-- function My:TimeStart( )
--     local st = self.glInfo.Value1[1].id;
--     local et = self.glInfo.Value1[2].value;
--     if et==0 then
--         et=24;
--     end
--     self.infinite.text=string.format( "每天%d-%d点不限购买次数",st,et);
--     self.st=st*60*60;
--     self.et=et*60*60;
   
-- end

function My:show( )
    --self:TimeStart();
    self:StageChange();
    self:AllBuy();
    self:BuyTimes();
    self:priceTxt( )
end

function My:priceTxt( )
    local glInfo = self.glInfo;
    self.price.text=glInfo.Value2[1].."元宝"
    self.priceTen.text=glInfo.Value2[4].."元宝"
end

function My:howPlay( )
    local str = XsActiveCfg["1020"].detail;
    UIComTips:Show(str, Vector3(244,-180,0),nil,nil,nil,400,UIWidget.Pivot.BottomLeft);
    -- self.des.gameObject:SetActive(true)
    -- self.desLb.text = str
end

-- function My:CloseDec()
--     self.des.gameObject:SetActive(false)
-- end

function My:Lsnr(fun)
    local CBM = CloudBuyMgr;
    CBM.eStage[fun](CBM.eStage,self.StageChange,self);
    CBM.eBuyInfo[fun](CBM.eBuyInfo,self.AllBuy,self);
    CBM.eBuy[fun](CBM.eBuy,self.BuyTimes, self);
    CBM.eChange[fun](CBM.eChange,self.show,self)
end

function My:BuyOne()
    -- local bought = CloudBuyMgr.bought;
    --local canBuy = CloudBuyMgr.canBuy;
    local glInfo = self.glInfo;
    if glInfo.Value2[1]>RoleAssets.Gold then
        MsgBox.ShowYesNo("元宝不足，是否充值？",self.yesCb,self);
        return;
    end
    CloudBuyMgr:buySend(1)
    -- if  bought<canBuy or My.maxBool then
    --     CloudBuyMgr:buySend()
    -- else
    --     UITip.Log("无购买次数");
    -- end
end

function My:BuyTen()
    -- local bought = CloudBuyMgr.bought;
    --local canBuy = CloudBuyMgr.canBuy;
    local glInfo = self.glInfo;
    if glInfo.Value2[4]>RoleAssets.Gold then
        MsgBox.ShowYesNo("元宝不足，是否充值？",self.yesCb,self);
        return;
    end
    CloudBuyMgr:buySend(10)
end
function My:yesCb()
    JumpMgr:InitJump(UICloudBuy.Name);
	VIPMgr.OpenVIP(1)
end
--倒计时显示
function My:timeShow()
    self:clearTime();
    self.timer = ObjPool.Get(DateTimer);
    self.timer.invlCb:Add(self.InvlCb, self);
    self.timer:OnedayDownStart();
    --self:InvlCb();
end

function My:InvlCb()
    self.timeDn.text=self.timer.remain;
    self.cur= TimeTool.GetSeverTodaySecond();
    -- if self.st<self.cur and self.cur <self.et then
    --     self.curMaxBool=true;
    --     if self.curMaxBool~=self.maxBool then
    --         self.maxBool=self.curMaxBool;
    --         self:BuyTimes();
    --     end
    -- else
    --     My.curMaxBool=false;
    --     if self.curMaxBool~=self.maxBool then
    --         self.maxBool=self.curMaxBool;
    --         self:BuyTimes();
    --     end
    -- end 
end

--刷新购买数量
function My:BuyTimes()
    self.bought.text = CloudBuyMgr.bought;
end


function My:OpenBigRCD( )
    UICloudBuy:OpenBigRecord(true);
end

--刷新库存数量
function My:AllBuy( )
    local glInfo = self.glInfo;
    local allcanbuy = glInfo.Value2[3];    
    local more = CloudBuyMgr.resNum;
    self.residue.text=string.format( "%d/%d",more,allcanbuy)
    self.silder.value=more/allcanbuy;
    self:showRecord();
end

--期数改变
function My:StageChange()
    self:timeShow();
    self:desCell();
    local stage = CloudBuyMgr.stage;
    if stage==0 then
        return;
    end
    local rwdInfo = tCloudBuy[stage];
    local SA =  soonTool.AddCell;
        self.Bigls1=soonTool.AddOneCell(self.bigRwd,rwdInfo.BigRWD.id,rwdInfo.BigRWD.num,1.5);
    local SRWD = rwdInfo.SRWD
    for i=1,#SRWD do
        SA(self.samRwd,self.samList,SRWD[i].id,SRWD[i].num,1,SRWD[i].eff);
    end
    self.need.text=rwdInfo.Need;
    self.samRwd:Reposition();
end

--记录购买刷新
function My:showRecord( )
    local rcinfo = CloudBuyMgr.allBuyInfo;
    if rcinfo==nil then
        return;
    end
    local pos = self.cbrcdname.transform.localPosition
    for i=1,#rcinfo do
        local rclst = self.rclst[i];
        if rclst==nil then
            rclst=soonTool.Get("cbrcdname");
            self.rclst[i]=rclst;
        end
        rclst.name=100+i;
        local lb = self:getLb(rclst);
        local item = ItemData[tostring(rcinfo[i].reward)]
        local itemlb = item.name
        local qua = UIMisc.LabColor(item.quality)
        local col = string.format( "[%s]",rcinfo[i].name )
        lb.text = string.format("[C6E3F7FF]%s[-]获得:%s%s[-]",col,qua,itemlb)
        local lbtex = lb:GetComponent(typeof(UILabel))
        local high = lbtex.height;
        pos.y=pos.y-high/2
        lb.transform.localPosition=pos;
        pos.y=pos.y-2-high/2
    end
end

function My:getLb(go)
    return ComTool.GetSelf(UILabel,go,self.Name);
end

--清理格子
function My:desCell( )
    soonTool.desCell(self.samList);
    soonTool.desOneCell(self.Bigls1);
    self.Bigls1=nil;
end

function My:clearTime()
    if self.timer==nil then
        return
    end
	self.timer:AutoToPool();
	self.timer = nil;
end
function My:Clear( )
    self:Lsnr("Remove");
    TableTool.ClearUserData(self);
    soonTool.desLst(self.rclst);
    self:desCell();
    self:clearTime();
end

return My;