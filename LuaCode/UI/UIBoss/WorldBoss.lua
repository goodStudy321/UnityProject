WorldBoss ={Name = "WorldBoss"}

local My = WorldBoss;
--疲劳数
My.times = nil;
--公共滚动类
My.ComView = nil;
--安钮
My.Btns = {};
My.uts={}
--类型
My.type = 1;
--地图Id
My.mapId = nil;
--怪物Id
My.MontId = nil;
-- --当前层
-- My.curLayer=nil;
--是否显示
-- My.isShowTip=false
function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:SetTimes()
    if self.Tired == nil then
        return;
    end
    local allTimes = NetBoss.GetBossAllTime();
    self.Tired.text = string.format("%s/%s",NetBoss.WorldTimes,allTimes);
end

--刷新数据
function My:Refresh(bossList, type)
    self:SetTimes();
    if bossList == nil then
        return;
    end
    if #bossList == 0 then
        return;
    end
    if self.ComView == nil then
        self.ComView = ObjPool.Get(UIComView);
        self.ComView:Init(self.root);
    end
    local info = bossList[1];
    self.MontId = info.type_id;
    self.mapId = info.map_id;
    --倒计时
    self:setResTimes()
    self.ComView:Open(bossList,type);
    --监听
    self:lsnr("Add")
end

function My:Open(go)
    -- local read =SettingSL:ReadOne("bosstipshow")
    -- My.isShowTip=read=="true" and true or false;
    local name = go.name;
    local CG = ComTool.Get;
    self.root = go;
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    local trans = go.transform;
    self.megObj=TFC(go,"merge")
    if NetBoss.isGuide<2 then
        self.megObj:SetActive(false)
    else
        self.megObj:SetActive(true)
    end
    self.megtrue=TFC(go,"merge/true")
    self.megLab = CG(UILabel,go,"merge/Label",name,false);
    UC(go,"merge",name,self.OnClickMegr,self,false)
    self.Tired = CG(UILabel,go,"BossTiredNum",name,false);
    self.resTimes=CG(UILabel,go,"resTimes",name,false);
    self.AddTimes=CG(UIButton,go,"BossTiredNum/AddTimes",name,false);
    self.ComView = ObjPool.Get(UIComView);
    self.ComView:Init(go);
    self.care = TransTool.FindChild(go,"Care",name);
    BossCare:Init(self.care);
    self.lv = User.instance.MapData.Level
    local islt=BossHelp.SelectLayer;
    if islt==nil then
        BossHelp.worldChoose(My.type)
        if BossHelp.SelectId~=nil and BossHelp.SelectId~=0 then
            BossHelp.ChoseBossCell(BossHelp.SelectId)
        end
        islt=BossHelp.SelectLayer;
        if islt == nil or islt==0 then 
            islt=1;
        end
    end
    local btnRoot = TF(trans,"Grid")
    for i = 1,5 do
        local path = string.format("Button%s",i);
        self.Btns[i] = TFC(btnRoot,path,name);
        self.uts[i]=CG(UIToggle,btnRoot,path,name);
        UC(btnRoot, path, name, self.BtnC, self);
    end
    self.uts[islt].value=true;
    self.cur=0;
    self:UpDataBsInf(islt);
    self:SetLayerBtn();
    self:setResTimes()
    self:ChangeMegrSuc(  )

    local E = UITool.SetLsnrSelf
	E(self.AddTimes, self.OnClickAddTimes, self)
end


function My:OnClickAddTimes(  )
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:Buy("世界Boss",31028,1)
end
function My:OnClickMegr(  )
  if  NetBoss.merge_times>1 then
    NetBoss.send3ci(1)
  else
    My:OpenMergeTip( )
  end 
end

function My:SendMg( num )
    NetBoss.send3ci(num)
end

function My:OpenMergeTip( )
    local vipLv = VIPMgr.GetVIPLv()
    local VipInfo =soonTool.GetVipInfo(vipLv)
    local bossMerge= VipInfo.bossMerge
    local nextTimes,vextvp = soonTool.FindNextNum("bossMerge",vipLv)
    self.vipLv=vipLv
    self.bossMerge=bossMerge
    self.vextvp=vextvp
    self.nextTimes=nextTimes
    if bossMerge<2 then
        if nextTimes==0 then
          return
        end
        UITip.Log(string.format( "达到VIP%s才可以合并挑战",vextvp ))
        return
    end
    UIMgr.Open(MergeTip.Name, self.megSetInfo, self)
end

function My:megSetInfo(  )
    MergeTip:SetInfo(self.vipLv,2,NetBoss.WorldTimes,self.bossMerge,self.vextvp,self.nextTimes,self.SendMg,self)
end


function My:ChangeMegrSuc(  )
 if NetBoss.merge_times>1  then
    self.megtrue:SetActive(true)
    self.megLab.text=string.format( "合并%s次", NetBoss.merge_times)
 else
    self.megtrue:SetActive(false)
    self.megLab.text=string.format( "合并次数", NetBoss.merge_times)
 end 

end

function My:lsnr( fun )
    NetBoss.eUpTieTime[fun](NetBoss.eUpTieTime,self.setResTimes,self)
    NetBoss.eMerge[fun](NetBoss.eMerge,self.ChangeMegrSuc,self)
end
--设置恢复状态
function My:setResTimes( )
    local str = "";
    local max = GlobalTemp["122"].Value2[2];
    local nowTimes = NetBoss.resumeTimes;
    if nowTimes>=max then
        str=InvestDesCfg["1750"].des;
        self.resTimes.text=str;
        return
    end
    local time=NetBoss.resumeTime;
    local nowTime =  TimeTool.GetServerTimeNow() / 1000; 
    local useTime = time-nowTime;
    if useTime>0 then
        self:StartTime(useTime)
    else
        self:EndCountDown(  )
    end
end
function My:StartTime(time)
	if self.Timer == nil then
	    self.Timer = ObjPool.Get(DateTimer);
        self.Timer.fmtOp = 3
        self.Timer.invlCb:Add(self.SetTime, self);
        self.Timer.complete:Add(self.EndCountDown, self);
	end
	self.Timer.seconds = time;
	self.Timer:Start();
    self.Timer.cnt = 0;
    self:SetTime()
end
function My:SetTime(  )
    if self.Timer == nil then
        return;
    end 
    if  self.resTimes==nil then
        self:ClearTime()
    end
    local str = self.Timer.remain
    str=str.."后恢复1次挑战次数"
    self.resTimes.text=str;
end
function My:EndCountDown(  )
    if self.resTimes==nil then
        return
    end
    self.resTimes.text="";
    self:ClearTime()
end
--设置层按钮
function My:SetLayerBtn()
    local layer = My.GetLayer(My.type);
    for i = 1,5 do
        if i <= layer then
            self.Btns[i]:SetActive(true);
        else
            self.Btns[i]:SetActive(false);
        end
    end
end

--获取层数
function My.GetLayer(type)
    local layer = 0;
    for k,v in pairs(SBCfg) do
        if v.type == type then
            if v.layer > layer then
                layer = v.layer;
            end
        end
    end
    return layer;
end

--点击层按钮
function My:BtnC()
    local uts =  self.uts;
    for i=1,#uts do
        if uts[i].value and self.cur ~= i then
            if self:checkClick(i) then
                self:UpDataBsInf(i);
            else
                uts[i].value=false
                uts[self.cur].value=true
            end
        end
    end
end

function My:checkClick(index  )
    local lst = GlobalTemp["124"].Value2
    local lock = lst[index]
    if self.lv>=lock then
        return true;
    end
    local str = string.format( "%s级开启",lock )
    UITip.Log(str)
    return false
end

function My:ClearTime( )
    if self.Timer ~= nil then
        self.Timer:AutoToPool();
        self.Timer = nil;
    end
end

function My:Close()
    self:lsnr("Remove")
    self:ClearTime( )
    if self.ComView == nil then
        return;
    end
    self.ComView:Close();
    self.ComView:Close();
    ObjPool.Add(self.ComView);
    self.ComView = nil;
end
function My:UpDataBsInf( btnClick )
    self:Close();
    BossModel:DestroyModel();
    self.cur=btnClick;
    BossHelp.curLayer=btnClick;
    NetBoss:ReqUpBInfo(My.type,btnClick);
end
--进入地图
function My:EnterMap()

    local cell = BossHelp.CurCell;
    if cell == nil then
        UITip.Log("请选择BOSS地图");
        return;
    end
    local id = cell.sceneId;
    self.mapId = id;
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        BossHelp.inSenceGo();
        return;
    end
    if NetBoss.isGuide==0 then
        id=90001
        SceneMgr:ReqPreEnter(id,false,true);
        return
    elseif NetBoss.isGuide==1 then
        id=90002
        SceneMgr:ReqPreEnter(id,false,true);
        return
    end
    if cell.isAlive ==false then
        UITip.Log("BOSS仍在复活中，不可挑战");
        return;
    end
    if cell.isOpen==false then
        UITip.Log("等级未达到，不可挑战");
        return;
    end
    if NetBoss.WorldTimes <1 and cell.canEnter==false  then
        UITip.Log("挑战次数已用完，不可挑战");
        -- local msg = "挑战次数已用完，不可挑战";
        -- MsgBox.ShowYesNo(msg,self.OKClk,self);
        return;
    end
    local gl = GlobalTemp["80"].Value3
    if self.lv>cell.LvTex+gl then
        -- local desc = string.format("大于BOSS等级%s级击败将不会有掉落奖励，是否继续前往?",gl); 
        -- MsgBox.ShowYesNo(desc, self.YesCb,self, "确定", self.NoCb,self, "取消");
        UITip.Log(string.format( "高于BOSS%s级，请挑战与等级相匹配的BOSS",gl))
        return
    end
    if NetBoss.merge_times>1 then
        if NetBoss.WorldTimes <NetBoss.merge_times  and cell.canEnter==false then
            UITip.Log("挑战次数不足，不可挑战");
            return
        end
    end
    self:UIClose()
    SceneMgr:ReqPreEnter(id,false,true);
end

function My:togChange( value )
    SettingSL:SaveOne( "bosstipshow",value )
end

function My:YesCb(  )
    self:UIClose()
    SceneMgr:ReqPreEnter( self.mapId,false,true);
end

function My:NoCb(  )
end

function My:UIClose(  )
    UIBoss:CloseC();
end

-- --确定点击
-- function My:OKClk()
--     if self.mapId == nil then
--         return;
--     end
--     self:UIClose()
--     SceneMgr:ReqPreEnter(self.mapId,false, true);
-- end