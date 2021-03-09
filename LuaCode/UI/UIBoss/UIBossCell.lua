
UIBossCell ={Name = "UIBossCell"}

local My = UIBossCell;
local AssetMgr=Loong.Game.AssetMgr;
local Time = UnityEngine.Time;
local TimeSpan = System.TimeSpan
local GO = UnityEngine.GameObject;
function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:DefineVariable();
    return o;
end

function My:Init(root)
    self.root = root.transform;
    local root = self.root;
    local name = root.name;
    local TF = TransTool.Find;
    local CG = ComTool.Get;
    local UCS = UITool.SetLsnrSelf;
    self.Name1 = CG(UILabel,root,"Name",name,false);
    self.Level = CG(UILabel,root,"Level",name,false);
    self.Icon = CG(UITexture,root,"BossIcon",name,false);
    self.EqpQua = CG(UILabel,root,"EquipQua",name,false);
    local path = "RefreshTime";
    self.RTR = TF(root,path,name);
    path = "RefreshTime/RTime";
    self.RT = CG(UILabel,root,path,name,false);
    self.RTG = TF(root,path,name);
    path = "RefreshTime/HasRefresh";
    self.HRG = TF(root,path,name);
    self.NumLab = CG(UILabel,root,"RefreshTime/num",false)
    self.Flag = TF(root,"Flag",name);
    self.Flag.gameObject:SetActive(false)
    self.OpenLv = CG(UILabel,root,"OpenLv",name,false);
    self.Select = TF(root,"Select",name);
    UCS(root,self.BossCellC,self,name, false);
    self.safe=TransTool.FindChild(root,"safety",tip);    
    --排序
    if self.what==0 or self.what==4 then
        root.name=1000+self.LvTex;
    else 
        root.name=1000+self.what;
    end
end

function My:DefineVariable()
--怪物BossID
self.MontId = nil;
--名称
self.NameTex = nil;
--等级
self.LvTex = 0;
--是否存活
self.isAlive = nil;
--刷新时间
self.RTimeTex = nil;
--副本Id
self.copyId = nil;
--图片名
self.IconTex = nil;
--掉落装备品阶
self.EqpQuaTex = nil;
--是否是当前选择的格子
self.IsSelect = nil;
--是否已经加载
self.isload=false;
--是否是安全区
self.isSafe=0;
--当前种类类
self.what=0;
--当前数量
self.curNum=0;
--地图id
self.sceneId=0;
--是否开启
self.isOpen=true
--是否允许进入
self.canEnter=false
end

--boss格子点击
function My:BossCellC(go)
    if LuaTool.IsNull(self.Select) then
        return;
    end
    if self.IsSelect== true then
        return;
    end
    local bool = self.isSafe==1 and true or false;
    BossHelp:TIPShow(bool);
    self.Select.gameObject:SetActive(true);
    BossHelp:SlctBossCell(self);
    self.IsSelect = true;
end

--清除选择
function My:ClearSelect()
    if  self.IsSelect == false then
        return;
    end
    if LuaTool.IsNull(self.Select) then
        return;
    end
    self.Select.gameObject:SetActive(false);
    self.IsSelect = false;
end

-- --设置boss信息
-- function My:SetBossInfo(name)
--     local ui = UIMgr.Get(name);
--     if ui ~= nil then
--         ui:SetInfo(self.MontId);
--     end
-- end

-- function My:Open()

-- end

--加载格子
function My:LoadCell(index,parent,view)
    self.parent = parent;
    self.view = view;
    self.index = index;
    self.isload=true;
    local name = "BossCell";
    local  go = soonTool.Get(name);
    if go==nil then
        BossHelp.ClassBig:SetPotorl()
        go = soonTool.Get(name);
    end
  self:LoadUd(go);
end

--加载完成
function My:LoadUd(go)
    self:Init(go);
    self:SetUID();
    self:AddToParent(go.transform);
    if self.view ~= nil then
        self.view:LoadCD();
    end
end
--加载Boss格子完成
-- function My:LoadD(go)
--     if self.isload == nil then
--         AssetMgr.Instance:Unload("BossCell", ".prefab",false);
--         GO.Destroy(go);
--         return;
--     end
--     soonTool.setPerfab(go,"BossCell")
--     local  go1 = soonTool.Get("BossCell");
--   self:LoadUd(go1);
-- end

--添加到父体
function My:AddToParent(go)
    if go == nil then
        return;
    end
    if self.parent == nil then
        return;
    end
    go.gameObject:SetActive(false);
    go.parent = self.parent;
    go.localPosition = Vector3.zero;
    go.localScale = Vector3.one;
    go.gameObject:SetActive(true);
end

--初始化数据
function My:InitD(monId,isAlive,time,curNum,roleNum,canEnter )
    local id = tostring(monId);
    local sb = SBCfg[id];
    if sb == nil then
        return;
    end
    self.lv = User.instance.MapData.Level
    self.what=sb.what;
    self.isGuide =false;
    self.type = sb.type
    self.canEnter=canEnter;
    if roleNum~=nil then
        self.roleNum=roleNum
    end
    -- if self.what==4 and NetBoss.isGuide  then
    --     local info = NetBoss.GuideInfo
    --     self.isAlive = true
    --     self.isGuide=true
    --     self.sceneId= info.sceneId
    -- else
        self.sceneId=sb.sceneId
        self.isAlive = isAlive;
    -- end
    self.MontId = id;
    self.RTimeTex = time;
    self.curNum=curNum;
    self.DrpLCN = 0;
    local mt = nil;
    if self.what==1 then
        mt= BinTool.Find(CollectionTemp,tonumber(monId))
        if mt == nil then
            return;
        end
        self.IconTex = mt.icon..".png";
    else
        mt = MonsterTemp[id];
        if mt == nil then
            return;
        end
        self.LvTex = mt.level;
        self.IconTex = mt.icon;
    end
    self.NameTex = mt.name;
    self.EqpQuaTex = sb.equipQua;
    self.isSafe=sb.safe;
    self:SetCopyId(sb);
end

--设置UI
function My:SetUID()
    self.Name1.text = self.NameTex;
    if self.what==0 then
        self.Level.transform.gameObject:SetActive(true);
        self.EqpQua.transform.gameObject:SetActive(true);
        self.Level.text = string.format("%s级",self.LvTex);
        self.EqpQua.text = tostring(self.EqpQuaTex);
    else
        self.Level.transform.gameObject:SetActive(false);
        self.EqpQua.transform.gameObject:SetActive(false);
    end
    if self.isSafe == 1 then
        self.safe:SetActive(true);
    else
        self.safe:SetActive(false);
    end
    self:SetIcon();
    self:SetReTime();
    self:SetSelect();
end

--设置选择
function My:SetSelect()
    local index = BossHelp.Index
    if self.index ~= index then
        self.Select.gameObject:SetActive(false);
        return;
    end
    self.Select.gameObject:SetActive(true);
    local bool = self.isSafe==1 and true or false;
    BossHelp:TIPShow(bool);
    BossHelp:SlctBossCell(self);
    self.IsSelect = true;
end

--设置头像
function My:SetIcon()
    AssetMgr.Instance:Load(self.IconTex,ObjHandler(self.LoadIcon,self));
end

--加载icon完成
function My:LoadIcon(obj)
	if self.Icon == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.Icon.mainTexture=obj;    
end

--设置更新时间
function My:SetReTime()
    local time = self.RTimeTex;
    if time ~= nil then
        self:SetBossOpenLv( )
        if self.isOpen==false then
            self.RTR.gameObject:SetActive(false);
            return
        end
        self.RTR.gameObject:SetActive(true);
        if self.isAlive == true  then
            self:SetRefDone(true);
        else
            self:SetRefDone(false);
            local sTime = math.floor(TimeTool.GetServerTimeNow()/1000);
            self.leftTime = time - sTime;
            self:StartCount();
            self:SetTime();
        end
    else
        self.RTR.gameObject:SetActive(false);
        self.Flag.gameObject:SetActive(false);
        self:SetOpenLv();
    end
end

--是否是副本
function My:IsCopy()
    local time = self.RTimeTex;
    if time ~= nil then
        return false;
    end
    return true;
end

--设置副本ID
function My:SetCopyId(sb)
    if self:IsCopy() == false then
        return;
    end
    self.copyId = sb.sceneId;
end

--设置开启等级
function My:SetOpenLv()
    self:ReSetG();
    if self.copyId == nil then
        return;
    end
    local Id = tostring(self.copyId);
    local info = CopyTemp[Id];
    if info == nil then
        return;
    end
    local level = self.lv
    if level >= info.lv then
        return;
    end
    self.OpenLv.text = string.format( "%s级后开启",info.lv);
    self.OpenLv.gameObject:SetActive(true);
end

function My:SetBossOpenLv( )
    if self.type==1 and self.lv<self.LvTex then
        local unloak = SceneTemp[tostring(self.sceneId)].unlocklv
        self.OpenLv.gameObject:SetActive(true);
        self.OpenLv.text = string.format( "%s级后开启",unloak);
        self.NumLab.gameObject:SetActive(false)
        self.HRG.gameObject:SetActive(false);
        self.isOpen=false;
    else
        self.isOpen =true;
    end
end

--重置对象
function My:ReSetG()
    self.Flag.gameObject:SetActive(false);
    self.HRG.gameObject:SetActive(false);
    self.RTG.gameObject:SetActive(false);
    self.OpenLv.gameObject:SetActive(false);
    self.NumLab.gameObject:SetActive(false)
end

--设置已经刷新
function My:SetRefDone(arg)
    if self.isOpen ==false then
        return
    end
    if self.what==0 or self.what ==4 then
        self.isAlive=arg
        self.Flag.gameObject:SetActive(not arg);
    end
    if self.what~=3 then
        if  self.type==1 then
            self.HRG.gameObject:SetActive(false);
            self.NumLab.gameObject:SetActive(arg)
            self.NumLab.text=string.format( "当前场景人数：%s",self.roleNum) 
            else
            self.HRG.gameObject:SetActive(arg);
            self.NumLab.gameObject:SetActive(false)
        end
    else
        self.HRG.gameObject:SetActive(false);
        self.NumLab.gameObject:SetActive(arg)
        self.NumLab.text=string.format( "剩余数量：%s",NetBoss.BossNum) 
    end
    self.RTG.gameObject:SetActive(not arg);
    self.OpenLv.gameObject:SetActive(false);
end

--设置计时完成
function My:SetCountDone()
    self:SetRefDone(true);
    self:StopTimer();
    -- if self.what~=0 then
    --     BossHelp:SendReqUpBInfo( )
    -- end
end

--设置时间
function My:SetTime()
    if self.Timer == nil then
        return;
    end
    self.RT.text = self.Timer.remain;
end

--开始计时
function My:StartCount()
    self.Timer = ObjPool.Get(DateTimer);
    self.Timer.seconds = self.leftTime+0.4;
    self.Timer.fmtOp = 0
    self.Timer.invlCb:Add(self.SetTime, self)
    self.Timer.complete:Add(self.SetCountDone, self)
    self.Timer:Start();
end

--停止计时
function My:StopTimer()
    if self.Timer == nil then
        return;
    end
    self.Timer:AutoToPool();
    self.Timer = nil;
end

function My:Close()
    BossHelp:TIPShow(false);
    if self.isload==true then
        AssetMgr.Instance:Unload(self.IconTex,false);
    end
    self:clearTime()
    if not LuaTool.IsNull(self.root) then
        soonTool.Add(self.root.gameObject,"BossCell");
    end
    self:ClearSelect();
    TableTool.ClearUserData(self);
    self:StopTimer();
    self.isload=nil;
    ObjPool.Add(self);
end
function My:clearTime()
    if self.Timer==nil then
        return
    end
	self.Timer:AutoToPool();
	self.Timer = nil;
end
function My:Dispose()
end