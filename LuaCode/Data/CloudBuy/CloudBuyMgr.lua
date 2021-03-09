CloudBuyMgr={Name="CloudBuyMgr"};
local My = CloudBuyMgr
--是否显示红点
My.isDot=true;

--已经购买数量
My.bought=0;

--期数
My.stage=0;

--全服数量
My.resNum=0;

--全服信息
My.allBuyInfo={};

My.bigBuyInfo = {}

My.eChange = Event()
--期数更新
My.eStage = Event();

--全服数据刷新
My.eBuyInfo=Event();

--大奖刷新
My.eBigRcd=Event();

--购买之类数据刷新
My.eBuy=Event();


function My:Init()
    self:AddLsnr();
    self.qinfo=ObjPool.Get(soonQlist);
    self.qinfo:Creat(30)
    self.bigfo = ObjPool.Get(soonQlist)
    self.bigfo:Creat(100)
end
  
function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName;
    PA("m_act_limitedtime_buy_info_toc", self.ResInfo, self);
    PA("m_act_limitedtime_buy_info_i_toc", self.ResBuyInfo, self);
    --PA("m_act_limitedtime_buy_end_toc", self.ResBig, self);
    PA("m_act_limitedtime_buy_toc", self.ResBuy, self);
    PA("m_act_limitedtime_buy_round_toc",self.ResStage, self);
end

--==============================--


-- 限时云购信息上线推送
function My:ResInfo(msg)
    self.resNum = msg.buy_num;
    self.logs = msg.logs;
    self.bigs = msg.big_reward_logs;
    self.stage = msg.stage
    self.bought = msg.times
    self.qinfo:Remove()
    self.allBuyInfo=self.qinfo:Add(self.logs);
    self.bigfo:Remove()
    self.bigBuyInfo = self.bigfo:Add(self.bigs);
    --self.eBuy();
    self.eChange()
end

function My.OpenCloudy( )
    local isOpen = UITabMgr.IsOpen(ActivityMgr.XSYG)
    if isOpen then
        UIMgr.Open(UICloudBuy.Name)
    end
end

--全服的刷新
function My:ResBuyInfo(msg)
    self.resNum = msg.buy_num;
    self.logs = msg.log
    self.allBuyInfo=self.qinfo:Add(self.logs);
    self:BigInfo()
    self.eBuyInfo();
end

function My:BigInfo()
    local num = #self.logs
    for i=1,num do
        if self.logs[i].type == 1 then
            table.insert( self.bigBuyInfo,1,self.logs[i])
        end
    end
end

--购买返回
function My:ResBuy(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
    else
        self.bought = msg.num;
        self.eBuy();
        UITip.Log("购买成功");
    end
end

--期数
function My:ResStage(msg)
    self.stage = msg.stage;
    self.eStage();
end

--==============================--

--购买
function My:buySend(times)
    local msg = ProtoPool.Get("m_act_limitedtime_buy_tos");
    msg.times=times
    ProtoMgr.Send(msg);
end

--更新红点
function My:UpRedDot()
    local actId = ActivityMgr.XSYG
    local info = ActivityTemp[tostring(actId)]
    local lv = User.MapData.Level
    if not info or info.lv > lv then return end
	if My.isDot then
		SystemMgr:ShowActivity(actId)
    else
		SystemMgr:HideActivity(actId)
	end
end


function My:Clear( )
    My.isDot=true;
    My.allBuyInfo=nil;
end

return My;