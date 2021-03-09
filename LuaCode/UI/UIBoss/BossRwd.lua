BossRwd = {Name = "BossRwd"}
local My = BossRwd;
require("UI/UIBoss/PBossRwd");
My.DrpCells = {};
function My:Init(go)
    self.root = go.transform;
    local root = self.root;
    local name = root.name;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    self.UITable = CG(UITable,root,"ItemTable",name,false);
    self.PRwdG = TF(root,"PRwdG",name);
    PBossRwd:Init(self.PRwdG);
end



--设置激活
function My:SetAct(show)
    if self.root == nil then
        return;
    end
    local go = self.root.gameObject;
    local act = go.activeSelf;
    if act == show then
        return;
    end
    go:SetActive(show);
end

--设置奖励
function My:SetRwd(monsId,type)
    self:ClearDrop();
    if type == 3 then  --个人boss
        self:SetRwdSt(false);
        PBossRwd:SetRwd(monsId);
        return;
    end
    self:SetRwdSt(true);
    self:SetDrop(monsId);
end

--设置奖励对象状态
function My:SetRwdSt(state)
    self.UITable.gameObject:SetActive(state);
    self.PRwdG:SetActive(not state);
end

--加载掉落格子完成
function My:LoadCD(go)
    self.DrpLCN = self.DrpLCN + 1;
    if self.DrpLCN < self.DrpN then
        return;
    end
    local b=self.UITable.gameObject.activeSelf 
    self.UITable.repositionNow=true;
end

--重置Table
function My:RepRwd()
    self.UITable:Reposition();
    PBossRwd:RepRwd();
end

--设置掉落物
function My:SetDrop(monsId)
    self.DrpN = 0;
    self.DrpLCN = 0;
    local id = tostring(monsId);
    if SBCfg[id]==nil then
        iTrace.Error("世界boss奖励没有配置id=",monsId)
        return;
    end
    local drops = SBCfg[id].drops;
    self.DrpN = #drops;
    if self.DrpN == 0 then
        return;
    end
    local it = nil;
    for i = 1, self.DrpN do
        it = ObjPool.Get(UIItemCell);
        self.DrpCells[i] = it;
        it:InitLoadPool(self.UITable.transform,0.8,self)
        it:UpData(drops[i])
    end
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
    self:ClearDrop();
    self.DrpN = nil;
    self.DrpLCN = nil;
    PBossRwd:Dispose();
    TableTool.ClearUserData(self);
end