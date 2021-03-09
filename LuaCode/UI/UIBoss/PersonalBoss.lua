PersonalBoss ={Name = "PersonalBoss"}

local My = PersonalBoss;

--进入副本次数
My.times = nil;
--公共滚动类
My.ComView = nil;
--类型
My.type = 3;
--地图id
My.mapId = nil;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--设置进入副本次数
function My:STimes(times)
    self.times = times;
end

--刷新数据
function My:Refresh(bossList)
    self.mapId = bossList[1].map_id;
    self:SetTired();
    if bossList == nil then
        return;
    end
    if #bossList == 0 then
        return;
    end
    if self.ComView == null then
        return;
    end
    self.ComView:Open(bossList,self.type);
end

--设置疲劳显示
function My:SetTired()
    local vipLv , str= self:GetVipEntTime();
    -- local copy = CopyTemp[tostring( self.mapId)];
    -- local base = copy == nil and 1 or copy.num;
    self.vipLv=vipLv
    local time = self:GetHasEntTime();
    self.Tired.text = self.vipLv-time .. "/" .. self.vipLv;
    -- local str  = "";
    local lv = VIPMgr.GetVIPLv()
    if lv==0 then
        lv=1
    end
    local info = soonTool.GetVipInfo(lv) 
    -- if info~=nil and info.BossDes~=nil then
    --     str=info.BossDes
    -- end
    if str==nil then
        str=""
    end
    self.vipDes.text=str;
end

--获取Vip进入次数
function My:GetVipEntTime()
    local lvStr = VIPMgr.GetVIPLv()
    local vipLv = soonTool.GetVipInfo(lvStr) 
    if vipLv == nil then
        return 0;
    end
    if vipLv.arg15 == nil then
        return 0;
    end
    return vipLv.arg15 ,vipLv.BossDes;
end

--获取已经进入次数
function My:GetHasEntTime()
    local key = tostring(CopyType.PBoss);
    local time = 0;
    local info = CopyMgr.Copy[key];
    if info ~= nil then
        time = info.Num;
    end
    return time;
end

function My:Open(go)
    local name = go.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local trans = go.transform;
    self.Tired = CG(UILabel,trans,"Surplus",name,false);
    self.vipDes=CG(UILabel,trans,"vipDes",name);
    self.ComView = ObjPool.Get(UIComView);
    self.ComView:Init(go);
end

function My:Close()
    self.times = nil;
    self.Tired = nil;
    self.ItemId = nil;
    self.Num = nil;
    if  self.ComView == nil then
        return
    end
    self.ComView:Close();
    ObjPool.Add(self.ComView);
    self.ComView = nil;
end


--进入地图
function My:EnterMap()
    local vipLv = VIPMgr.GetVIPLv(); 
    -- if vipLv<4 then
    --     UITip.Log("需要达到VIP4")
    --     return;
    -- end
    local cell = BossHelp.CurCell;
    if cell == nil then
        UITip.Log("请选择BOSS地图")
        return;
    end
    local copyId = tostring(cell.copyId);
    local info = CopyTemp[copyId];
    if info == nil then
        return;
    end
    local level = User.instance.MapData.Level;
    if level < info.lv then
        UITip.Log("副本未开启")
        return;
    end
    local time = self:GetHasEntTime();
    local vipTime = self.vipLv;
    if time >= vipTime then
        UITip.Log("进入副本次数已经用完");
        return;
    end
    local mId = cell.MontId;
    local sbInfo = SBCfg[mId];
    if sbInfo == nil then
        iTrace.Error("没有世界地图表信息");
        return;
    end
    local id = SBCfg[mId].sceneId;
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        return;
    end
    local itemId = 0;
    local num = 0;
    self.copyId = info.id;  
    --免费进入      

    local vipinfo =soonTool.GetVipInfo(vipLv);
    if vipinfo~=nil and vipinfo.BossFree~=nil and  time < vipinfo.BossFree  then
        SceneMgr:ReqPreEnter(self.copyId, true,true);       
        return;
    end
    local cost = info.inputCost;
    local enterTime =time + 1;
    local itemId, num = BossHelp.GetCostInfo(self.mapId,enterTime);
    -- if cost ~= nil then
    --     itemId = cost.id;
    --     num = cost.value;
    --     if vipinfo~=nil and vipinfo.BossHalf==1  then
    --         num=math.ceil( num/2 ) 
    --     end
    -- end
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:doTipInfo("个人boss",self.copyId,itemId,num)
end