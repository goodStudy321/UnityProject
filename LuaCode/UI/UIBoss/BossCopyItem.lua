BossCopyItem = Super:New{Name="BossCopyItem"}
local My = BossCopyItem
local GO = UnityEngine.GameObject;
local BKMgr = BossKillMgr.instance;


function My:Init( )
    local trans = self.root
    local go = trans
    local name = trans.name;
    local TF = TransTool.FindChild;
    local CG = ComTool.Get;
    local UCS = UITool.SetLsnrSelf;
    self.Name1 = CG(UILabel,trans,"Name",name,false);
    self.Level = CG(UILabel,trans,"Level",name,false);
    self.anger = CG(UILabel,trans,"anger",name,false);
    self.anger.transform.gameObject:SetActive(false);
    self.RfrFlag = CG(UILabel,trans,"RfrFlag",name,false);
    self.RfrTime = CG(UILabel,trans,"RfrTime",name,false);
    self.Select = TF(trans,"Select",name);
    UCS(go,self.InfoC,self,name, false);
end

function My:showInfo( info )
    self.Name1=info.name
    self.Level=info.lv
    self:SetReTime(true)
    self:SetSltState(self.show);
end

function My:SetReTime(isAlive)
   if self.show and isAlive then
    self:setFalg(true)
   else
    self:setFalg(false)
    self.leftTime=self.info.time
    self:StartCount()
    if self.show then
        self:SetTomb();
    end
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
    local info = self.info
    local name = string.format( "%s(%s级)",info.name,info.lv);
    self.BossName.text = name;
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
--设置信息
function My:setInfo( info )
    self.info=info
    self.typeId = info.mosId
    self.show=false
    self.go=soonTool.Get("BossItem")
    if info.show==1 then
        self.show=true
        BossCopyLst.trueId=self.info.id
        self.pos = Vector3.New(info.pos.k * 0.01, 0, info.pos.v * 0.01);
        self:InfoC(self.go)
    end
    self.root = self.go.transform;
    self:Init()
    self:showInfo( info )
end

--信息点击
function My:InfoC(go)
    if self.show then
        BKMgr:StartNavPath(self.pos,0,3,self.typeId);
        self:SetSltState(true);
    else
        UITip.Log("不能寻路")
    end
end
--设置选择状态
function My:SetSltState(arg)
    if self.Select == nil then
        return;
    end
    self.Select:SetActive(arg);
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
--设置时间
function My:SetTime()
    if self.Timer == nil then
        return;
    end
    if self.RfrTime == nil then
        return;
    end
    self.RfrTime.text = self.Timer.remain;
    if self.show then
        self:SetRTime(self.Timer.remain);
    end
end
--设置刷新时间
function My:SetRTime(tStr)
    if self.RTime == nil then
        return;
    end
    local tStr = string.format("%s后刷新",tStr);
    self.RTime.text = tStr;
end
--计时完成
function My:CountDone()
    if self.Timer == nil then
        return;
    end
    self.Timer:AutoToPool();
    self.Timer = nil;
end

function My:setFalg( b )
    self.RfrFlag.gameObject:SetActive(b)
    self.RfrTime.gameObject:SetActive(not b)
end


function My:Dispose()
    self:CountDone()
    self:DestroyTomb();
    if self.root == nil then
        return;
    end
    GO.Destroy(self.root);

end