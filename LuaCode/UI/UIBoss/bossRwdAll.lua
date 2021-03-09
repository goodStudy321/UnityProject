bossRwdAll={Name="bossRwdAll"}
local My = bossRwdAll

--初始化
function My:Init(root)
    self.go=root.gameObject
    self.go:SetActive(true)
    self.root = root;
    local name = root.name;
    local CG = ComTool.Get;
    local CGS = ComTool.GetSelf;
    local TF = TransTool.Find;
    local rwdRoot = TF(root,"BossRwd")
    local UC = UITool.SetLsnrClick;
    self.PRwdGTbl = CGS(UITable,rwdRoot,name);
    self.SlyDrpTbl = CG(UITable,rwdRoot,"2SlyDrpTbl",name,false);
    self.RareDrpTbl = CG(UITable,rwdRoot,"4RareDrpTbl",name,false);
    UC(root,"close",name,self.Close,self);
    UC(root,"lock",name,self.Close,self);
    self:SetRwd()
end

--设置奖励
function My:SetRwd()
    local monsId = BossHelp.SelectId
    self:ClearDrop();
    self.DrpCells = {};
    self.Len = 0;
    self.aLen = 0;
    self.curLen = 0;
    self:SetDrop(monsId,1);
    self:SetDrop(monsId,2);
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
        cellRoot = self.RareDrpTbl.transform;
    elseif dType == 2 then -- 珍稀掉落
        drops = SBCfg[id].rareDrops;
        cellRoot = self.SlyDrpTbl.transform;
    end
    len=#drops;
    if len == 0 then
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

function My:Clear()
    if self.root==nil or LuaTool.IsNull(self.root) then
        return ;
       end
    self.go:SetActive(true)
    self:ClearDrop();
    TableTool.ClearUserData(self);
end

function My:Close(  )
    BossHelp:CloseModCam()
end

return My;