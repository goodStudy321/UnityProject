WildFBoss ={Name = "WildFBoss"}

local My = WildFBoss;
My.uts={};
--公共滚动类
My.ComView = nil;
--类型
My.type = 4;
--地图Id
My.mapId = nil;
--安钮
My.Btns = {};

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
    self.mapId = bossList[1].map_id;
    self.ComView:Open(bossList,4);
    self:setAllTime()
    self:SetCanEnterNum();
    self:SetLayerNum(  )
end

function My:Open(go)
    self.root = go;
    local ED = EventDelegate
    local EC = ED.Callback
    local ES = ED.Set
    local name = go.name;
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    local CG = ComTool.Get;
    local trans = go.transform;
    self.CanEnterNum = CG(UILabel,trans,"CanEnterNum",name,false);
    self.Vipdec = CG(UILabel,trans,"Vipdec",name,false);
    self.peopleNUm=CG(UILabel,trans,"peopleNUm",name,false);
    self.care=TransTool.FindChild(trans,"Care",name);
    BossCare:Init(self.care);
  
    local btnRoot = TF(trans,"Grid")
    for i = 1,5 do
        local path = string.format("Button%s",i);
        self.Btns[i] = TFC(btnRoot,path,name);
        self.uts[i]=CG(UIToggle,btnRoot,path,name);
        UC(btnRoot, path, name, self.BtnC, self);
    end
    -- self.SceIdLst={"90101","90102","90103"};
    local lock1 =  SceneTemp["90101"].unlocklv
    local lock2 =  SceneTemp["90102"].unlocklv
    local lock3 =  SceneTemp["90103"].unlocklv
    self.SceLockLvl={lock1,lock2,lock3}
    self.lv = User.instance.MapData.Level;
    if self.lv >=  lock3 then
        self.btnNum=3
        -- self.uts[3].value=true
    elseif self.lv >= lock2 then
            self.btnNum=2
            -- self.uts[2].value=true
    else
            -- self.uts[2].enabled=false;
            self.btnNum=1
            -- self.uts[1].value=true
    end
    self.cur= self.btnNum;
    local islt=BossHelp.SelectLayer;
    if islt~=nil and self.uts[islt]~=nil then
        self.uts[islt].value=true;
        self.cur=islt;
    else
        self.uts[self.cur].value=true;
    end
    self:UpDataBsInf( self.cur);
    self:SetLayerBtn()
    
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

--设置场景人数
function My:SetLayerNum(  )
    self.peopleNUm.text= NetBoss.CurLayerRole.."人";
   
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

function My:Close()
    if self.ComView == nil then
        return;
    end
    self.ComView:Close();
    ObjPool.Add(self.ComView);
    self.ComView = nil;
end

--设置剩余进入次数
function My:SetCanEnterNum()
    self.leftTime = self:GetLeftTime();
    local leftTime = self.leftTime <0 and 0 or self.leftTime 
    self.CanEnterNum.text = string.format( "%s/%s",leftTime,self.allTime)
    self:SetNext(  )
end

function My:SetNext(  )
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local allTime = 0
    local vpLv = VIPMgr.GetVIPLv()
    local len = #VIPLv-1
    for i=vpLv,len do
        vpLv=i+1
        local vipInfo = soonTool.GetVipInfo(vpLv)
        if vipInfo==nil then
            vpLv=0;
            break;
        end
        if vipInfo.arg10~=nil then
            allTime=vipInfo.arg10
            if allTime>self.allTime then
                break;
            end
        end
    end
    local str = ""
    if vpLv~=0 then
        str=string.format( "(提升到[67cc67]VIP%s[-]，每日可挑战[67cc67]%s次[-])",vpLv,allTime )
    end
    self.Vipdec.text=str
end

--设置剩余次数
function My:GetLeftTime()
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local enterTime =  NetBoss.GetEnterTime(mapCfg.mapchildtype);
    self.enterTime=enterTime
    local allTime =self.allTime
    local leftTime = allTime - enterTime;
    return leftTime;
end

--设置总次数
function My:setAllTime()
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local vipLv = VIPMgr.GetVIPLv()
    local VipInfo =soonTool.GetVipInfo(vipLv)
    local vipTime = VipInfo.arg10;
    local allTime=vipTime;
    self.allTime=allTime
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
    local lst =self.SceLockLvl
    local lock = lst[index]
    if self.lv>=lock then
        return true;
    end
    local str = string.format( "%s级开启",lock )
    UITip.Log(str)
    return false
end

function My:UpDataBsInf( btnClick )
    self:Close();
    BossModel:DestroyModel();
    self.cur=btnClick;
    BossHelp.curLayer=btnClick;
    NetBoss:ReqUpBInfo(self.type,btnClick);
end

--进入地图
function My:EnterMap()
    if self.mapId == nil then
        UITip.Log("地图Id为空");
        return;
    end
    if User.SceneId == self.mapId then
        UITip.Log("已经在此场景");
        BossHelp.inSenceGo();
        return;
    end
    if self.leftTime <= 0 then
        UITip.Log("进入次数已经用完");
        return;
    end
    local enterTime =self.enterTime + 1;
    local itemId, num = BossHelp.GetCostInfo(self.mapId,enterTime);
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:doTipInfo("幽冥地界",self.mapId,itemId,num)
end

return My;