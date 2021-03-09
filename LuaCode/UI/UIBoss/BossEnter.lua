BossEnter={Name="BossEnter"}
local My = BossEnter
local BKMgr = BossKillMgr.instance;
--
function My:enterPos( Mapid,pos )
    self.pos=pos
    self.scenceInfo=SceneTemp[tostring(Mapid)];
    local bossPlace = self.scenceInfo.mapchildtype; 
    local type = 0
    if bossPlace==2 then
        type = 2
    elseif bossPlace == 4 then
        type=4
    elseif bossPlace == 15 then
        type=6
    elseif bossPlace == 16 then
        type=5
    elseif bossPlace == 17 then
        type=7
    end
    self:enterScence(type,Mapid)
    self.way=1;
    self:Lnsr( "Add" )
end

function My:Lnsr( fun )
    EventMgr[fun]("OnChangeScene", My.findPos)
    BossCostTip.eClose[fun](BossCostTip.eClose,self.Clear,self)
end
function My.findPos( )
    if My.mapId==User.SceneId then
        local info = SceneTemp[tostring(My.mapId)]
        User.instance:StartNavPathPure(My.pos,info.map)
    end
    My:Clear()
end
--进入 
function My:enterScence(type,Mapid )
    self.mapId=Mapid;
    if type==2 then
        self:HomeOfBoss()
    elseif type == 4 then
        self:WildBoss()
    elseif type == 5 then
        self:IsLanboss()
    elseif type == 6 then
        self:OutIsLanboss()
    elseif type == 7 then
        self:RemnantBoss()
    end
end
-------------------------------
--世界Boss
------------------------------------

-------------------------------
--洞天福地
------------------------------------
function My:HomeOfBoss(  )
    local sceneId = tostring(self.mapId);
    local info = SceneTemp[sceneId];
    if info == nil then
        return;
    end
    self.costGold= info.costGold
    self.lvStr = VIPMgr.GetVIPLv()
    self.canInto = info.canEnterVIP ==nil and 0 or info.canEnterVIP
    if info == nil then
        return;
    end
    if User.SceneId == self.mapId then
        UITip.Log(conText);
        -- BossHelp.inSenceGo();
        return;
    end
    local lvStr = self.lvStr
    local canInto = self.canInto
    local NoStr = "取消"
    if lvStr < canInto then
        self.isUnder4=true;
        NoStr="购买VIP"
        local text = string.format( "[b1a495]VIP等级不足,请前往购买VIP。\n([67cc67]VIP%s免费进入[-])[-]",info.fvipLv )
        MsgBox.ShowYes(text,self.homeNoBtn,self,NoStr);
        return;
    end

    if lvStr<4 then
        self.isUnder4=true;
        NoStr="购买VIP"
    end
    -- if  self.enterTime<self.freeTimes or 
      if lvStr >=info.fvipLv  then
        SceneMgr:ReqPreEnter(self.mapId, false, true);
      else 
        local p_sb = ObjPool.Get(StrBuffer);
        p_sb:Apd("[b1a495]VIP等级不足，是否花费[67cc67]"):Apd(self.costGold)
        :Apd("绑定元宝[-]或[67cc67]元宝[-]？([67cc67]VIP"):Apd(info.fvipLv):Apd("免费进入[-])[-]");
        text = p_sb:ToStr();
        MsgBox.ShowYesNo(text,self.homeOKBtn,self,nil,self.homeNoBtn,self,NoStr);
        ObjPool.Add(p_sb);
    end
end
--确定回调
function My:homeOKBtn()
    local assetNum = RoleAssets.GetCostAsset(3);
    if assetNum <  self.costGold then
        local conText = "绑定元宝或元宝不足";
        UITip.Log(conText);
        return;
    end
    SceneMgr:ReqPreEnter(self.mapId, false, true);
end
--取消回调
function My:homeNoBtn()
    if self.isUnder4 then
        VIPMgr.OpenVIP(5)
    end
    self:Clear()
end
-----------------------------------
--幽冥禁地
------------------------------------
function My:WildBoss()
    if self.mapId == nil then
        UITip.Log("地图Id为空");
        return;
    end
    if User.SceneId == self.mapId then
        -- BossHelp.inSenceGo();
        return;
    end
    self.leftTime = self:GetLeftTime();
    if self.leftTime <= 0 then
        UITip.Log("进入次数已经用完");
        return;
    end
    local enterTime =self.enterTime + 1;
    local itemId, num = BossHelp.GetCostInfo(self.mapId,enterTime);
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:doTipInfo("幽冥地界",self.mapId,itemId,num)
end

--设置剩余次数
function My:GetLeftTime()
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local enterTime =  NetBoss.GetEnterTime(mapCfg.mapchildtype);
    self.enterTime=enterTime
    local allTime = self:setAllTime()
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
    local allTime = 0
        local vipInfo = soonTool.GetVipInfo(vipLv)
        local vipTime = vipInfo.arg10;
        if vipTime ~= nil then
            allTime = vipTime;
        end
    return allTime
end
-----------------------------------
--神兽岛
------------------------------------
function My:IsLanboss()
    local id = self.mapId 
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        -- BossHelp.inSenceGo();
        return;
    end
    local allTimes = NetBoss.GetBossAllTime();
    if NetBoss.islTimes >= allTimes then
        self.mapId = id;
        local msg = "今日挑战次数已用完，进入地图将无法对boss造成伤害，是否进入";
        MsgBox.ShowYesNo(msg,self.islOKClk,self,"确定",self.islNoClik,self,"取消");
        return;
    end
    SceneMgr:ReqPreEnter(id,false,true);
end
-----------------------------------
--神兽岛(跨服)
------------------------------------
function My:OutIsLanboss()
    local id = self.mapId 
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        -- BossHelp.inSenceGo();
        return;
    end
    local allTimes = NetBoss.GetBossAllTime();
    if NetBoss.islTimes >= allTimes then
        self.mapId = id;
        local msg = "今日挑战次数已用完，进入地图将无法对boss造成伤害，是否进入";
        MsgBox.ShowYesNo(msg,self.islOKClk,self,"确定",self.islNoClik,self,"取消");
        return;
    end
    SceneMgr:ReqPreEnter(id,false,true);
end
--确定点击
function My:islOKClk()
    if self.mapId == nil then
        return;
    end
    SceneMgr:ReqPreEnter(self.mapId,false,true);
end
--确定点击
function My:islNoClik()
    self:Clear()
    return
end

-----------------------------------
--远古遗迹
------------------------------------
function My:RemnantBoss()
    local id =self.mapId
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        -- BossHelp.inSenceGo();
        return;
    end
    local leftTime = self:GetRemLeftTime();
    if leftTime <= 0 then
        UITip.Log("进入次数已经用完");
        return;
    end
    local enterTime = self.enterTime + 1;
    local itemId, num = BossHelp.GetCostInfo(self.mapId,enterTime);
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:doTipInfo("远古遗迹",self.mapId,itemId,num)
end
--设置剩余次数
function My:GetRemLeftTime()
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local enterTime =  NetBoss.GetEnterTime(mapCfg.mapchildtype);
    self.enterTime=enterTime
    local vipLv = VIPMgr.GetVIPLv()
    local allTime = 0;
    if vipLv ~= 0 then
        local vipInfo = soonTool.GetVipInfo(vipLv)
        local vipTime = vipInfo.RemBoss;
        if vipTime ~= nil then
            allTime = vipTime;
        end
    end
    local leftTime = allTime - enterTime;
    return leftTime;
end


function My:Clear( )
    self.mapId=nil
    My:Lnsr( "Remove" )
end

return My;