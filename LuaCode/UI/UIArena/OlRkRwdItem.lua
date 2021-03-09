OlRkRwdItem = { Name = "OlRkRwdItem"}
local My = OlRkRwdItem;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:SetPro();
    return o;
end

function My:SetPro()
    self.RewardCells = {};
end

function My:SetInfo(go,rankRwdInfo,index)
    self.isOpen = true;
    self.root = self:CloneGo(go,go.transform.parent);
    self.root.name = index;
    local trans = self.root.transform;
    local name = trans.name;
    local CG = ComTool.Get;

    self.Bg = CG(UISprite,trans,"RankBg",name,false);
    self.RankSpr = CG(UISprite,trans,"RankSprite",name,false);
    self.RankIcon = CG(UISprite,trans,"RankIcon",name,false);
    self.Rank = CG(UILabel,trans,"Rank",name,false);
    self.UITable = CG(UITable,trans,"RwdTable",name,false);

    -- self:SetBg(index);
    -- self:SetRankSprite(index);
    self:SetRankInfo(rankRwdInfo);
    self:SetRwdInfo(rankRwdInfo);
end

--设置背景图
function My:SetBg(index)
    local num,lnum = math.modf(index/2);
    if lnum == 0 then
        self.Bg.spriteName = "list_bg_1";
    else
        self.Bg.spriteName = "list_bg_2";
    end
end

--设置排名背景图
function My:SetRankSprite(index)
    local sprName = "";
    if index == 1 then
        sprName ="rank_info_1";
    elseif index == 2 then
        sprName ="rank_info_2";
    elseif index == 3 then
        sprName ="rank_info_3";
    else
        sprName ="";
    end
    self.RankSpr.spriteName = sprName;
end

--设置排名信息
function My:SetRankInfo(info)
    if info.RankIcon ~= nil then
        self.RankIcon.spriteName = info.RankIcon;
    end

    local rank = nil;
    if info.startRank == info.endRank then
        rank = info.startRank;
    else
        rank = string.format( "%s-%s",info.startRank,info.endRank);
    end
    local str = string.format( "第%s名",rank);
    self.Rank.text = str;
end

--设置奖励
function My:SetRwdInfo(info)
    local index = 1
    if info.RwdHonor ~= nil and info.RwdHonor > 0 then
        local honorStr = math.NumToStr(info.RwdHonor);
        local honorCell = ObjPool.Get(UIItemCell);
        honorCell:InitLoadPool(self.UITable.transform,0.8,self);
        honorCell:UpData(info.HonorIcon,honorStr);
        self.RewardCells[index] = honorCell;
        index = index + 1;
    end

    if info.RwdCoin ~= nil and info.RwdCoin > 0 then
        local coinStr = math.NumToStr(info.RwdCoin);
        local coinCell = ObjPool.Get(UIItemCell);
        coinCell:InitLoadPool(self.UITable.transform,0.8,self);
        coinCell:UpData(info.CoinIcon,coinStr);
        self.RewardCells[index] = coinCell;
        index = index + 1;
    end
    
    if info.expRate ~= nil and info.expRate > 0 then
        local exp = PropTool.GetExp(info.expRate/10000);
        local expStr = math.NumToStr(exp);
        local expCell = ObjPool.Get(UIItemCell);
        local expIcon = 100;
        expCell:InitLoadPool(self.UITable.transform,0.8,self);
        expCell:UpData(expIcon,expStr);
        self.RewardCells[index] = expCell;
        index = index + 1;
    end

    if info.drops == nil then
        return;
    end
    local len = #info.drops;
    local it = nil;
    for i = 1, len do
        it = ObjPool.Get(UIItemCell);
        self.RewardCells[index] = it;
        it:InitLoadPool(self.UITable.transform,0.8,self);
        it:UpData(info.drops[i].k,info.drops[i].v);
        index = index + 1;
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    if self.isOpen == false then
        GO.Destroy(go);
        return;
    end
    self.UITable:Reposition();
end

--克隆对象
function My:CloneGo(go,parent)
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = parent;
    root.transform.localPosition = Vector3.zero;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

--清除奖励格子
function My:ClearRwds()
    if self.RewardCells == nil then
        return;
    end
    local length = #self.RewardCells;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.RewardCells[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.RewardCells[i] = nil;
    end
end

--清除数据
function My:Clear()
    self:ClearRwds();
    self.root.transform.parent = nil;
    GO.Destroy(self.root);
    TableTool.ClearUserData(self);
end