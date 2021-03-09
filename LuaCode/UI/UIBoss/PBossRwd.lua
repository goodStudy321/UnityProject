PBossRwd = {Name == "PBossRwd"}
local My = PBossRwd;

--初始化
function My:Init(go)
    self.root = go.transform;
    local root = self.root;
    local name = root.name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild
    local CGS = ComTool.GetSelf;
    local UC = UITool.SetLsnrClick;
    self.PRwdGTbl = CGS(UITable,go,name);
    self.SlyDrpTbl = CG(UITable,root,"2SlyDrpTbl",name,false);
    self.sly1 = TFC(root,"1RareDrpTitle")
    self.sly2 = TFC(root,"2SlyDrpTbl")
    self.sly3 = TFC(root,"3SlyDrpTitle")
    self.RareDrpTbl = CG(UITable,root,"4RareDrpTbl",name,false);
    self.doubleOpen1= TFC(root,"1RareDrpTitle/doubleOpen")
    self.doubleOpen2= TFC(root,"3SlyDrpTitle/doubleOpen")
    UC(root,"1RareDrpTitle/ToggleRewardbtn",name,self.OpenModCam,self);
    UC(root,"3SlyDrpTitle/ToggleRewardbtn",name,self.OpenModCam,self);
    -- self:Lsnr( "Add" )
end

-- function My:Lsnr( fun )
--     NetBoss.edouble[fun](NetBoss.edouble,self.SetDouble,self)
-- end

-- function My:SetDouble( )
--     if LuaTool.IsNull(self.doubleOpen1) then
--        return
--     end
--     if BossHelp.curType==2 and NetBoss.doubleISOpen then
--         self.doubleOpen1:SetActive(true)
--         self.doubleOpen2:SetActive(true)
--     else
--         self.doubleOpen1:SetActive(false)
--         self.doubleOpen2:SetActive(false)
--     end
-- end

--打开记录
function My:OpenModCam(go )
    BossHelp:OpenModCam(2)
end
--设置奖励
function My:SetRwd(monsId)
    self:ClearDrop();
    self.DrpCells = {};
    self.Len = 0;
    self.aLen = 0;
    self.curLen = 0;
    self:SetDrop(monsId,2);--先加载顺序不可逆
    self:SetDrop(monsId,1);
    -- self:SetDouble( )
end

--加载掉落格子完成
function My:LoadCD(go)
    self.curLen = self.curLen + 1;
    if self.curLen < self.aLen then
        return;
    end
    self:RepRwd();
end

--重置Table
function My:RepRwd()
    self.SlyDrpTbl:Reposition();
    --self.slyW.autoResizeBoxCollider = true;
    self.RareDrpTbl:Reposition();
    self.PRwdGTbl:Reposition();
end

--设置掉落物
function My:SetDrop(monsId,dType)
    local id = tostring(monsId);
    local drops = nil;
    local cellRoot = nil;
    local len = 0;
    if dType == 1 then -- 必掉奖励
        drops = SBCfg[id].drops;
        len=3 < #drops and 3 or #drops;
        cellRoot = self.RareDrpTbl.transform;
        if len==0 then
            self.sly3:SetActive(false)
        else
            self.sly3:SetActive(true)
        end
    elseif dType == 2 then -- 珍稀掉落
        drops = SBCfg[id].rareDrops;
        len=9 < #drops and 9 or #drops;
        if len==0 then
            self.sly1 :SetActive(false)
            self.sly2 :SetActive(false)
        else
            self.sly1 :SetActive(true)
            self.sly2 :SetActive(true)
        end
        cellRoot = self.SlyDrpTbl.transform;
    end
    if len == 0 then
        if dType==1 then
           
        elseif dType == 2 then -- 珍稀掉落
      
        end
        return;
    end
    self.aLen = self.aLen + len;
    local it = nil;
    for i = 1, len do
        local itemid = drops[i]
        local itemInfo = UIMisc.FindCreate(itemid)
        if itemInfo.type==5 then
            self:SpCellData( itemInfo,cellRoot )
        else
            it = ObjPool.Get(UIItemCell);
            table.insert(self.DrpCells, it)
            it:InitLoadPool(cellRoot,0.8,self)
            it:UpData(drops[i])
        end
    end
    self.Len = self.Len + len;
    self:RepRwd();
end

function My:SpCellData( itemInfo,cellRoot )
    local item = ObjPool.Get(SPCell)
    item:InitLoadPool(cellRoot,0.8)
    item:BossSpData(itemInfo.id)
    table.insert(self.DrpCells, item)
end

--销毁掉落物图片
function My:ClearDrop()
    if self.DrpCells == nil then
        return;
    end
    local length = #self.DrpCells;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.DrpCells[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.DrpCells[i] = nil;
    end
    self.DrpCells = nil;
end

function My:Dispose()
    -- self:Lsnr( "Remove" )
    self:ClearDrop();
    TableTool.ClearUserData(self);
end