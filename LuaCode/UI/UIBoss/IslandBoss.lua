IslandBoss =Super:New{Name = "IslandBoss"}

local My = IslandBoss;
--疲劳数
My.times = nil;
--公共滚动类
My.ComView = nil;
--按钮
My.Btns = {};
My.uts={};
--类型
My.type = 5;
--地图Id
My.mapId = nil;
--怪物Id
My.MontId = nil;

local NB = NetBoss;

-- function My:New(o)
--     o = o or {}
--     setmetatable(o,self);
--     self.__index = self;
--     return o;
-- end


--刷新数据
function My:Refresh(bossList, type)
    self:ShowInfo();
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
    self.ComView:Open(bossList,type);
end

function My:Open(go)
    local name = go.name;
    local CG = ComTool.Get;
    self.root = go;
    local TFC = TransTool.FindChild;
    local TF = TransTool.Find
    local UC = UITool.SetLsnrClick;
    local trans = go.transform;
    self.ComView = ObjPool.Get(UIComView);
    self.ComView:Init(go);
    self.care = TransTool.FindChild(go,"Care",name);
    BossCare:Init(self.care);

    local islt=BossHelp.SelectLayer or 1 ;
    local canRoot = TF(trans,"canDo");
    self.crystal=CG(UILabel,canRoot,"crystal");
    self.crystal2=CG(UILabel,canRoot,"crystal2");
    self.times=CG(UILabel,canRoot,"times");
    self.AddTimes=CG(UIButton,canRoot,"times/AddTimes",name,false);
    local btnRoot = TF(trans,"Grid")
    for i = 1,5 do
        local path = string.format("Button%s",i);
        self.Btns[i] = TFC(btnRoot,path,name);
        self.uts[i]=CG(UIToggle,btnRoot,path,name);
        UC(btnRoot, path, name, self.BtnC, self);
    end
    local E = UITool.SetLsnrSelf
    E(self.AddTimes, self.OnClickAddTimes, self)
    islt=  islt==nil or 1
    islt= islt==0 or 1
    self.uts[islt].value=true;
    self.cur=0;
    self:BtnC();
    self:SetLayerBtn();
    self:lsnr("Add");
    self:ShowInfo( )
end
function My:OnClickAddTimes(  )
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:use("神兽岛",35505,1)
end
--监听
function My:lsnr(fun)
    NB.eUseAddIsl[fun](NB.eUseAddIsl,self.ShowInfo,self);
    NB.eCollect[fun](NB.eCollect,self.ShowInfo,self);
end
--展示一些信息
function My:ShowInfo( )
    self.crystal.text=NetBoss.Col1Isltime();
    self.crystal2.text=NetBoss.Col2Isltime();
    self.times.text=NB.GetAllIslTimes()-NB.islTimes.."/"..NB.GetAllIslTimes();
end

-- function My:SetTimes()
--     if self.Tired == nil then
--         return;
--     end
--     local allTimes = NB.GetBossAllTime();
--     self.Tired.text = string.format("%s/%s",allTimes-NB.TieTimes,allTimes);
-- end

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
            self:UpDataBsInf(i);
        end
    end
end

function My:Close()
    self:lsnr("Remove");
    if self.ComView == nil then
        return;
    end
    self.ComView:Close();
    ObjPool.Add(self.ComView);
    self.ComView = nil;
end
function My:UpDataBsInf( btnClick )
    self:Close();
    BossModel:DestroyModel();
    self.cur=btnClick;
    BossHelp.curLayer=btnClick;
    NB:ReqUpBInfo(self.type,btnClick);
end
--进入地图
function My:EnterMap()
    -- if true then
    --     UITip.Error("地图未开启")
    --     return 
    -- end
    local cell = BossHelp.CurCell;
    if cell == nil then
        UITip.Log("请选择BOSS地图");
        return;
    end
    local mId = cell.MontId;
    local sbInfo = SBCfg[mId];
    if sbInfo == nil then
        UITip.Log("没有世界地图表信息");
        return;
    end
    local id = SBCfg[mId].sceneId;
    if User.SceneId == id then
        UITip.Log("已经在此场景");
        BossHelp.inSenceGo();
        return;
    end
    local allTimes = NB.GetBossAllTime();
    if NB.islTimes >= allTimes then
        self.mapId = id;
        local msg = "今日挑战次数已用完，进入地图将无法对boss造成伤害，是否进入";
        MsgBox.ShowYesNo(msg,self.OKClk,self);
        return;
    end
    self:UIClose()
    SceneMgr:ReqPreEnter(id,false,true);
end
function My:UIClose(  )
    UIBoss:CloseC();
end

--确定点击
function My:OKClk()
    if self.mapId == nil then
        return;
    end
    self:UIClose()
    SceneMgr:ReqPreEnter(self.mapId,false,true);
end