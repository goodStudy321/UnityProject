RemnantBoss =Super:New{Name = "RemnantBoss"}

local My = RemnantBoss;

--公共滚动类
My.ComView = nil;
--按钮
My.Btns = {};
My.uts={};
--类型
My.type = 7;
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
    self:SetCanEnterNum( );
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
    self.CanEnterNum = CG(UILabel,trans,"CanEnterNum",name,false);
    BossCare:Init(self.care);
    local islt=BossHelp.SelectLayer==nil and 1 or BossHelp.SelectLayer;
    islt=islt==0 and 1 or islt
    local btnRoot = TF(trans,"Grid")
    for i = 1,5 do
        local path = string.format("Button%s",i);
        self.Btns[i] = TFC(btnRoot,path,name);
        self.uts[i]=CG(UIToggle,btnRoot,path,name);
        UC(btnRoot, path, name, self.BtnC, self);
    end
    self.uts[islt].value=true;
    self.cur=0;
    self:BtnC();
    self:SetLayerBtn();
    self:Lsnr("Add")
end
function My:Lsnr( fun )
    BossHelp.eSltCare[fun](BossHelp.eSltCare,self.doCareActive,self);
end
function My:doCareActive( what )
    self.care:SetActive(what~=3)
end

--设置剩余进入次数
function My:SetCanEnterNum()
    local leftTime = self:GetLeftTime();
    self.CanEnterNum.text = tostring(leftTime);
end

--设置剩余次数
function My:GetLeftTime()
    local mapCfg = SceneTemp[tostring(self.mapId)];
    if mapCfg == nil then
        return;
    end
    local enterTime =  NetBoss.GetEnterTime(mapCfg.mapchildtype);
    self.enterTime=enterTime
    local vipLv = VIPMgr.GetVIPLv()
    local allTime = 0;
    local vipInfo = soonTool.GetVipInfo(vipLv)
    local vipTime = vipInfo.RemBoss;
    if vipTime ~= nil then
        allTime = vipTime;
    end
    local leftTime = allTime - enterTime;
    return leftTime;
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
            self:UpDataBsInf(i);
        end
    end
end

function My:Close()
    if self.ComView == nil then
        return;
    end
    self:Lsnr("Remove")
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
    local leftTime = self:GetLeftTime();
    if leftTime <= 0 then
        UITip.Log("进入次数已经用完");
        return;
    end
    local enterTime = self.enterTime + 1;
    local itemId, num = BossHelp.GetCostInfo(self.mapId,enterTime);
    UIMgr.Open(BossCostTip.Name)
    BossCostTip:doTipInfo("远古遗迹",self.mapId,itemId,num)
end
function My:UIClose(  )
    UIBoss:CloseC();
end

