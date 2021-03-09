BLstInfo = { Name = "BLstInfo" }
local My = BLstInfo;
local GO = UnityEngine.GameObject;
local BKMgr = BossKillMgr.instance;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init(go,b)
    go = self:CloneGo(go,go.transform.parent);
    self.root = go;
    local trans = go.transform;
    local name = go.name;
    local TF = TransTool.FindChild;
    local CG = ComTool.Get;
    local UCS = UITool.SetLsnrSelf;

    self.Name1 = CG(UILabel,trans,"Name",name,false);
    self.Level = CG(UILabel,trans,"Level",name,false);
    self.anger = CG(UILabel,trans,"anger",name,false);
    if b~=true then
        self.RfrFlag = CG(UILabel,trans,"RfrFlag",name,false);
        self.RfrTime = CG(UILabel,trans,"RfrTime",name,false);
    else
        self.smTime = CG(UILabel,trans,"smTime",name);
    end
    self.Select = TF(trans,"Select",name);
    self.Select:SetActive(false);
    UCS(go,self.InfoC,self,name, false);
end

--克隆
function My:CloneGo(go,parent)
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = parent;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

--设置数据
function My:SetData(value)
    self.AllInfo=value;
    self.typeId = value.typeId;
    local info=nil
    if value.what==3 then
        return;
    end
    if value.what==0 or value.what==2 or value.what==4 then
        info = self.GetMonsInfo(value.typeId);
        if info == nil then
            return;
        end
        if value.what==2 then
            self.Level.text = string.format("%s个",value.lv);
            self.RfrFlag.gameObject:SetActive(false);
        else
            self.Level.text = string.format("%s级",value.lv);
            self:SetPos(value.typeId);
        end
    elseif value.what==1 then
        info = BinTool.Find(CollectionTemp,value.typeId);
        self.Level.text = string.format("%s个",value.lv);
        self.RfrFlag.gameObject:SetActive(false);
    end
    self.Name1.text = info.name;
    self:SetReTime(value.isAlive,value.nxtRfTime)
    self:doAnger(info)
    if SBCfg[tostring(self.typeId)].safe==1 then
        local color = Color.New(102,195,78,255)/255;
        self.Name1.color=color;
    end
    self.isSmall=false
end

function My:doAnger(info )
    if info.anger == nil or info.anger ==0 then
        self.anger.gameObject:SetActive(false)
    else
        self.anger.gameObject:SetActive(true)
        self.anger.text = math.ceil( info.anger/60 ) 
    end
end
--设置数据
function My:SetSmData(typeId,pos,time)
    self.typeId = typeId;
    local info = self.GetMonsInfo(typeId);
    if info == nil then
        return;
    end
    self:smTimeDo( time )
    self.Name1.text = info.name;
    self.Level.text = string.format("%s级",info.level);
    self.pos = pos
    self.root.name=info.level
    self.isSmall=true
    self:doAnger(info)
end
function My:smTimeDo( time )
    if time==nil or time==0 then
        self.smTime.text="";
    else
        local sTime = math.floor(TimeTool.GetServerTimeNow()/1000);
        self.sleftTime = time - sTime;
        self:sStartCount();
        self:sSetTime();
    end
end

--设置位置
function My:SetPos(typeId)
    local info = SBCfg[tostring(typeId)];
    if info == nil then
        return;
    end
    self.pos = Vector3.New(info.pos.k * 0.01, 0, info.pos.v * 0.01);
end

--设置更新时间
function My:SetReTime(isAlive,nxtRfrTime)
    local time = nxtRfrTime;
    if time ~= nil then
        if isAlive == true then
            self:StopTimer();
            self:SetRefDone(true);
        else
            if self.AllInfo.what==0 then
                self:SetRefDone(false);
                else
                self:SetReGo(false);
            end
            local sTime = math.floor(TimeTool.GetServerTimeNow()/1000);
            self.leftTime = time - sTime;
            self:StartCount();
            self:SetTime();
        end
    else
        self:StopTimer();
        self:SetRefDone(true);
    end
end

--设置墓碑
function My:SetTomb()
    if self.bLoad == true then
        return;
    end
    self.bLoad = true;
    Loong.Game.AssetMgr.LoadPrefab("SK_Boss_sb01all",GbjHandler(self.LoadDone,self));
end

--墓碑加载完成
function My:LoadDone(go)
    if go == nil then 
        return;
    end
    if self.root == nil then
        GO.Destroy(go);
        return;
    end
    if self.pos == nil then
        return;
    end
    ShaderTool.eResetGo(go)
    self.TombG = go;
    local trans = go.transform;
    local pos = self.pos;
    local posY = BKMgr:GetTerrainHeight(pos);
    pos.y = posY;
    trans.position = pos;
    trans.localScale = Vector3.one;
    --local angle = BKMgr:GetCamEAngls();
    --trans.eulerAngles = angle;
    self:InitBossTitle(go);
    self:SetBossName();
end

--初始化Boss 的Title
function My:InitBossTitle(go)
    local CG = ComTool.Get;
    local trans = go.transform;
    self.BossName = CG(UILabel,trans,"Title/BossName",name,false);
    self.RTime = CG(UILabel,trans,"Title/RTime",name,false);
end

--设置Boss名称
function My:SetBossName()
    local info = self.GetMonsInfo(self.typeId);
    if info == nil then
        return;
    end
    local name = string.format( "%s(%s级)",info.name,info.level);
    self.BossName.text = name;
end

--设置刷新时间
function My:SetRTime(tStr)
    if self.RTime == nil then
        return;
    end
    local tStr = string.format("%s后刷新",tStr);
    self.RTime.text = tStr;
end

--销毁坟墓
function My:DestroyTomb()
    if self.TombG == nil or self.bLoad~=true then
        return;
    end
    self.bLoad = false;
    AssetMgr:Unload("SK_Boss_sb01all",".prefab",false);
    GO.Destroy(self.TombG);
    self.TombG = nil;
end

--设置已刷新
function My:SetRefDone(arg)
    local bool = nil;
    if arg == true  then
        bool = false;
        self:DestroyTomb();
    else
        bool = true;
        self:SetTomb();
    end
    if self.RfrFlag == nil then
        return;
    end
    if self.RfrTime == nil then
        return;
    end
    self.RfrFlag.gameObject:SetActive(arg);
    self.RfrTime.gameObject:SetActive(bool);
end

--设置刷新状态
function My:SetReGo( arg )
    self.RfrFlag.gameObject:SetActive(arg);
    self.RfrTime.gameObject:SetActive(not bool);
end

--计时完成
function My:CountDone()
    self:StopTimer();
    if LuaTool.IsNull(self.RfrFlag) then
        return;
    end
    if LuaTool.IsNull(self.RfrTime) == nil then
        return;
    end
    self.RfrFlag.gameObject:SetActive(true);
    self.RfrTime.gameObject:SetActive(false);
end

--计时完成
function My:sCountDone()
    self:sStopTimer()
    if self.smTime == nil then
        return;
    end
    self.smTime.text="";
end

--设置时间
function My:SetTime()
    if self.Timer == nil then
        return;
    end
    if self.RfrTime == nil then
        return;
    end
    self.RfrTime.text = self.Timer.remain;
    self:SetRTime(self.Timer.remain);
end
--设置时间
function My:sSetTime()
    if self.sTimer == nil then
        return;
    end
    if self.smTime == nil then
        return;
    end
    self.smTime.text = self.sTimer.remain;
end
--小怪计时
function My:sStartCount( )
    if self.sTimer == nil then
        self.sTimer = ObjPool.Get(DateTimer);
        self.sTimer.fmtOp = 3;
        self.sTimer.apdOp = 1;
        self.sTimer.seconds = self.sleftTime;
        self.sTimer.invlCb:Add(self.sSetTime, self)
        self.sTimer.complete:Add(self.sCountDone, self)
        self.sTimer:Start();
    else
        self.sTimer:Stop();
        self.sTimer.seconds = self.sleftTime;
        self.sTimer:Start();
    end
end


--开始计时
function My:StartCount()
    if self.Timer == nil then
        self.Timer = ObjPool.Get(DateTimer);
        self.Timer.fmtOp = 3;
        self.Timer.apdOp = 1;
        self.Timer.seconds = self.leftTime;
        self.Timer.invlCb:Add(self.SetTime, self)
        self.Timer.complete:Add(self.CountDone, self)
        self.Timer:Start();
    else
        self.Timer:Stop();
        self.Timer.seconds = self.leftTime;
        self.Timer:Start();
    end
end

--停止计时
function My:StopTimer()
    if self.Timer == nil then
        return;
    end
    self.Timer:AutoToPool();
    self.Timer = nil;
end
--停止计时
function My:sStopTimer()
    if self.sTimer == nil then
        return;
    end
    self.sTimer:AutoToPool();
    self.sTimer = nil;
end
--获取怪物信息
function My.GetMonsInfo(typeId)
    local idStr = tostring(typeId);
    local info = MonsterTemp[idStr];
    if info == nil then
        return nil;
    end
    return info;
end

--信息点击
function My:InfoC(go)
    UIBossList:SetCurInfo(self);
    self:SetSltState(true);
    if self.AllInfo==nil or self.AllInfo.what==0 or self.AllInfo.what==4 then
        if self.pos == nil then
            return;
        end
        if self.isSmall==true then
            BKMgr:StartNavPath(self.pos,0,3,self.typeId);
            return
        end
        if self.AllInfo==nil then
            BKMgr:StartNavPath(self.pos,0,3,self.typeId);
        else
            local check =BossHelp:CheckAtkLim(self.typeId )
            if not check then
                local desc = "当前等级较Boss等级过高，无法对BOSS造成伤害，是否继续前往?"; 
                MsgBox.ShowYesNo(desc, self.YesCb,self, "确定", self.NoCb,self, "取消");
            else
                BKMgr:StartNavPath(self.pos,0,3,self.typeId);
            end
        end
    else 
        User:StopNavPath();
        UITip.Error( self.Name1.text.."不能寻路")
    end
end

function My:YesCb(  )
    BKMgr:StartNavPath(self.pos,0,3,self.typeId);
end

function My:NoCb(  )
end

--设置选择状态
function My:SetSltState(arg)
    if self.Select == nil then
        return;
    end
    self.Select:SetActive(arg);
end

function My:DestroyGo()
    self:StopTimer();
    self:CountDone()
    self:sCountDone()
    self:DestroyTomb();
    if self.root == nil then
        return;
    end
    GO.Destroy(self.root);
    self.root = nil;
    self.typeId = nil;
    self.pos = nil;
    ObjPool.Add(self);
end