UIActRankInfo = Super:New{Name = "UIActRankInfo"}
local My = UIActRankInfo;
My.RankStr = {}
My.RankStr[1] = "一"
My.RankStr[1] = "二"
My.RankStr[1] = "三"
My.RankStr[1] = "四"
My.RankStr[1] = "五"

function My:Ctor()
    --奖励列表
    self.RwdList = {}
end

--设置数据
function My:SetData(go,itemData)
    self.root = go;
    self.itemData = itemData;
    local trans = go.transform;
    local name = trans.name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local UCS = UITool.SetLsnrSelf;

    self.Rank = CG(UILabel,trans,"Rank",name,false);
    self.playerName = CG(UILabel,trans,"Name",name,false);
    self.RwdTable = CG(UITable,trans,"RwdTbl",name,false);

    self:InitData();
end

--设置数据
function My:InitData()
    self:SetRank();
    self:SetName();
    self:SetRwd();
end

--刷新数据(奖励是固定的不需要刷新)
function My:RfrData(itemData)
    self.itemData = itemData;
    self:SetRank();
    self:SetName();
end

--设置排名
function My:SetRank()
    if self.Rank == nil then
        return;
    end
    local rank = self.itemData.id;
    rank = string.format("第%s名",rank);
    self.Rank.text = rank;
end

--设置名字
function My:SetName()
    if self.playerName == nil then
        return;
    end
    local name = self.itemData.des;
    if name == nil or name == "" then
        name = "虚位以待";
    end
    self.playerName.text = name;
end

--设置奖励
function My:SetRwd()
    local rwds = self.itemData.rewardList;
    for i = 1,#rwds do
        local item = ObjPool.Get(UIItemCell);
        item:InitLoadPool(self.RwdTable.transform,0.8,self);
        item:UpData(rwds[i].id, 1);
        table.insert(self.RwdList, item);
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    self.RwdTable:Reposition();
end

--清除奖励格子
function My:ClearRwdList()

end

function My:Dispose()
    local isNull = LuaTool.IsNull(self.root);
    if isNull == false then
        Destory(self.root);
        self.root = nil;
    end
    TableTool.ClearListToPool(self.RwdList)
end