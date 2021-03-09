HomeOfBoss ={Name = "HomeOfBoss"}

local My = HomeOfBoss;

--公共滚动类
My.ComView = nil;
--类型
My.type = 2;
--地图Id
My.mapId = nil;
My.uts={};
--怪物Id
My.MontId = nil;
--安钮
My.Btns = {};
--第一层场景id
My.firstScence=90021

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--刷新数据
function My:Refresh(bossList)
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
    self.ComView:Open(bossList,self.type);
    self:SetInto();
    self:SetDblTime( )
end

function My:Open(go)
    local name = go.name;
    self.root = go;
    local ED = EventDelegate
    local EC = ED.Callback
    local ES = ED.Set
    
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    local trans = go.transform;
    self.care=TransTool.FindChild(trans,"Care",name);
    self.intoDec=CG(UILabel,trans,"intoDec");
    -- self.BossTiredNum=CG(UILabel,trans,"BossTiredNum");
    -- self.v0=CG(UILabel,trans,"v0");
    if  VIPMgr.GetVIPLv()==0 then
        -- self.v0.text=InvestDesCfg["1050"].Name
    end
    BossCare:Init(self.care);

    local islt=BossHelp.SelectLayer;
    if islt==nil or islt==0 then
        islt=self:homeChoose()
    end
    local btnRoot = TF(trans,"Grid")
    for i = 1,5 do
        local path = string.format("Button%s",i);
        self.Btns[i] = TFC(btnRoot,path,name);
        self.uts[i]=CG(UIToggle,btnRoot,path,name);
        UC(btnRoot, path, name, self.BtnC, self);
    end
    self.dblab=TFC(trans,"dblab")
    self.madBoss=TFC(trans,"madBoss")
    self.doubleTime=CG(UILabel,trans,"dblab/doubleTime");
    self.dblab:SetActive(false)
    self.madBoss:SetActive(false)
    self.uts[islt].value=true;
    self.cur=0;
    self:BtnC();
    self:SetLayerBtn();
    -- self:SetTie()
    self:lsnr("Add")
end
--洞天vip选择
function My:homeChoose( )
   local cen = 1
   local MyVip = VIPMgr.GetVIPLv()
    for i=2,5 do
        local scid = My.firstScence-1+i;
        local sceneId = tostring(scid);
        local info = SceneTemp[sceneId];
        if info.fvipLv <= MyVip then
            cen=cen+1
        else
            return cen
        end
    end
    return cen    
end

function My:lsnr( fun )
    NetBoss.edouble[fun](NetBoss.edouble,self.SetDblTime,self)
end

function My:SetDblTime( )
    if NetBoss.doubleISOpen then
        local time=NetBoss.doubleEndTime;
        local nowTime =  TimeTool.GetServerTimeNow() / 1000; 
        local useTime = time-nowTime;
        if useTime>0 then
            self.dblab:SetActive(true)
            self.madBoss:SetActive(true)
            self:StartTime(useTime)
        else
            self:EndCountDown(  )
        end
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
    if  self.dblab==nil then
        self:ClearTime()
    end
    local str = self.Timer.remain
    self.doubleTime.text=str;
end
function My:EndCountDown(  )
    if self.dblab==nil then
        return
    end
    self.dblab:SetActive(false)
    self.madBoss:SetActive(false)
    self:ClearTime()
end
function My:ClearTime( )
    if self.Timer ~= nil then
        self.Timer:AutoToPool();
        self.Timer = nil;
    end
end

--设置挑战次数
-- function My:SetTie(  )
-- local max = NetBoss.GetAllCaveTimes()
-- self.curTimes = NetBoss.GetLessCaveTimes()
-- self.BossTiredNum.text=string.format( "%s/%s",self.curTimes,max )
-- end
--设置进入条件
function My:SetInto(  )
    local sceneId = tostring(self.mapId);
    local info = SceneTemp[sceneId];
    self.scenInfo=info
    if info == nil then
        return;
    end
    self.costGold= info.costGold
    self.lvStr = VIPMgr.GetVIPLv()
    self.canInto = info.canEnterVIP ==nil and 0 or info.canEnterVIP
    local text = ""
    if self.lvStr < self.canInto  then
        text = string.format( "提升到VIP%s可进入",self.canInto  )
    elseif self.lvStr<info.fvipLv then
        text = string.format( "花费%s元宝可进入(优先消耗绑元)",self.costGold )
    end
    self.intoDec.text=text
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

function My:Close()
    self:lsnr("Remove")
    self:ClearTime( )
    if self.ComView == nil then
        return;
    end
    self.ComView:Close();
    ObjPool.Add(self.ComView);
    self.ComView = nil;
    self.mapId = nil;
    self.MontId = nil;
    self.isUnder4=false;
end

--点击层按钮
function My:BtnC()
    local uts =  self.uts;
    for i=1,#uts do
        if uts[i].value and self.cur ~= i then
            self:UpDataBsInf(i);
        end
    end
end


function My:UpDataBsInf( btnClick )
    self:Close();
    BossModel:DestroyModel();
    self.cur=btnClick;
    NetBoss:ReqUpBInfo(My.type,btnClick);
end
--进入地图
function My:EnterMap()
    local info = self.scenInfo
    if info == nil then
        return;
    end
    if User.SceneId == self.mapId then
        local conText = "已经在此场景!";
        UITip.Log(conText);
        BossHelp.inSenceGo();
        return;
    end
    
    local lvStr = self.lvStr
    local canInto = self.canInto
    local NoStr = "取消"
    if lvStr < canInto then
        self.isUnder4=true;
        NoStr="购买VIP"
        local text = string.format( "[b1a495]VIP等级不足,请前往购买VIP。\n([67cc67]VIP%s免费进入[-])[-]",info.fvipLv )
        MsgBox.ShowYes(text,self.NoBtn,self,NoStr);
        return;
    end

    if lvStr<4 then
        self.isUnder4=true;
        NoStr="购买VIP"
    end
    self.fvipLv=info.fvipLv
    self.NoStr=NoStr
    --挑战次数
	-- if self.curTimes ==0 then
    --     local desc = string.format("BOSS挑战次数已用完，将无法对\nBoss进行攻击，是否继续进入"); 
    --     MsgBox.ShowYesNo(desc, self.YesCb,self, "确定")
    --     return
    -- end
    if lvStr >=info.fvipLv  then
        SceneMgr:ReqPreEnter(self.mapId, false, true);
    else 
        local p_sb = ObjPool.Get(StrBuffer);
        p_sb:Apd("[b1a495]VIP等级不足，是否花费[67cc67]"):Apd(self.costGold)
        :Apd("绑定元宝[-]或[67cc67]元宝[-]？([67cc67]VIP"):Apd(info.fvipLv):Apd("免费进入[-])[-]");
        text = p_sb:ToStr();
        MsgBox.ShowYesNo(text,self.OKBtn,self,nil,self.NoBtn,self,NoStr);
        ObjPool.Add(p_sb);
    end
end

function My:YesCb( )
    if self.lvStr >=self.fvipLv  then
        SceneMgr:ReqPreEnter(self.mapId, false, true);
    else 
        local p_sb = ObjPool.Get(StrBuffer);
        p_sb:Apd("[b1a495]VIP等级不足，是否花费[67cc67]"):Apd(self.costGold)
        :Apd("绑定元宝[-]或[67cc67]元宝[-]？([67cc67]VIP"):Apd(self.fvipLv):Apd("免费进入[-])[-]");
        text = p_sb:ToStr();
        MsgBox.ShowYesNo(text,self.OKBtn,self,nil,self.NoBtn,self,self.NoStr);
        ObjPool.Add(p_sb);
    end
end

--确定回调
function My:OKBtn()
    local assetNum = RoleAssets.GetCostAsset(3);
    if assetNum <  self.costGold then
        local conText = "绑定元宝或元宝不足";
        UITip.Log(conText);
        return;
    end
    SceneMgr:ReqPreEnter(self.mapId, false, true);
end

--取消回调
function My:NoBtn()
    if self.isUnder4 then
        VIPMgr.OpenVIP(5)
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