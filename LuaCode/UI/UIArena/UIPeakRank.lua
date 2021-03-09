require("UI/UIArena/PkRkItem")
UIPeakRank = {Name = "UIPeakRank"}
local My = UIPeakRank;
My.MyRank = nil;
My.Ranks = {}

function My:Open(go)
    go:SetActive(true);
    self.root = go;
    local trans = go.transform;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;
    local name = go.name;
    self.UITable = CG(UITable,trans,"ScrollView/Table",name,false);
    self.OwnerRank = TF(trans,"OwnerRank",name);
    self.OwnerRank:SetActive(false);
    self.OtherRank = TF(trans,"OtherRank",name);
    self.OtherRank:SetActive(false);
    self:SetOwnerRank();
    self:SetRanks();
    UC(trans,"CloseBtn",name,self.Close,self);
end

--设置自己的排行榜
function My:SetOwnerRank()
    My.MyRank = PkRkItem:New();
    local ownerRk = self.OwnerRank.transform;
    My.MyRank:Init(self.OwnerRank,ownerRk.parent,ownerRk.localPosition);
    local info = Peak.MyRank;
    if info == nil then
        return;
    end
    My.MyRank:SetData(info.rank,info.roleName,info.roleScore,true);
end

--设置所有排行榜
function My:SetRanks()
    local index = 1;
    for k,v in pairs(Peak.Ranks) do
        local rank = PkRkItem:New();
        rank:Init(self.OtherRank,self.UITable.transform,nil);
        rank:SetData(v.rank,v.roleName,v.roleScore,false);
        My.Ranks[v.rank] = rank;
        index = index + 1;
    end
    self.UITable:Reposition();
end

function My.ClearRanks()
    for k,v in pairs(My.Ranks) do
        v:Clear();
        My.Ranks[k] = nil;
    end
end

function My:Close()
    self.root:SetActive(false);
    My.MyRank:Clear();
    self.ClearRanks();
    TableTool.ClearUserData(self);
end