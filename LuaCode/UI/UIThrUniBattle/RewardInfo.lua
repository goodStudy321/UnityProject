RewardInfo = {}
local My = RewardInfo;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:SetPro();
    return o;
end

function My:SetPro()
    --奖励格子加载完成计数
    self.RewardLCN = 0;
    --奖励格子
    self.RewardCells = {}
    self.isOpen = false;
end

function My:Open(go,rankInfo)
    self.isOpen = true;
    local item = GO.Instantiate(go);
    item = item.transform;
    item.name = ActvHelper.RankToStr(rankInfo.rank);
    item.parent = go.transform.parent;
    item.localPosition = Vector3.zero;
    item.localScale = Vector3.one;
    self.root = item;
    local CG = ComTool.Get;
    self.CellBg = CG(UISprite,item,"CellBg",name,false);
    self.RankLbl = CG(UILabel,item,"RankLbl",name,false);
    self.NameLbl = CG(UILabel,item,"NameLbl",name,false);
    self.RwdTbl = CG(UITable,item,"RewardTbl",name,false);
    self.NameLbl.text = rankInfo.roleName;
    self:SetData(rankInfo);
    self:SetActive(true);
end

function My:SetActive(active)
    if self.root.gameObject.activeSelf == active then
        return;
    end
    self.root.gameObject:SetActive(active);
end

--设置背景图
function My:SetBG(index)
    local num,lnum = math.modf(index/2);
    if lnum == 0 then
        self.CellBg.spriteName = "list_bg_1";
    else
        self.CellBg.spriteName = "list_bg_2";
    end
end

function  My:SetData(rankInfo)
    self:SetBG(rankInfo.rank);
    self.RankLbl.text = tostring(rankInfo.rank);
    local rkInfo = My.GetRkInfo(rankInfo.rank);
    if rkInfo ~= nil then
        self:SetRewardUI(rkInfo);
    end
end

--获取排名奖励信息
function My.GetRkInfo(rank)
    local len = #ThrRankRwd;
    for i = 1,len do
        if rank >= ThrRankRwd[i].startRank and rank <= ThrRankRwd[i].endRank then
            return ThrRankRwd[i];
        end
    end
    return nil;
end

--加载奖励格子完成
function My:LoadCD(go)
    if self.isOpen == false then
        GO.Destroy(go);
        return;
    end
    self.RewardLCN = self.RewardLCN + 1;
    if self.RewardLCN < self.RewardN then
        return;
    end
    self.RwdTbl:Reposition();
end

--设置奖励UI
function My:SetRewardUI(rkInfo)
    self:ClearRwdCells();
    local drops = rkInfo.drops;
    if drops == nil then
        return;
    end
    local len = #drops;
    self.RewardN = len;
    if rkInfo.expRate ~= nil and rkInfo.expRate > 0 then
        local exp = PropTool.GetExp(rkInfo.expRate/10000);
        local expStr = math.NumToStr(exp);
        local expCell = ObjPool.Get(UIItemCell);
        local expIcon = 100;
        expCell:InitLoadPool(self.RwdTbl.transform,0.6,self);
        expCell:UpData(expIcon,expStr);
        self.RewardCells[len+1] = expCell;
        self.RewardN = len + 1;
    end
    if self.RewardN == 0 then
        return;
    end
    local it = nil;
    for i = 1, len do
        it = ObjPool.Get(UIItemCell);
        self.RewardCells[i] = it;
        it:InitLoadPool(self.RwdTbl.transform,0.6,self)
        it:UpData(drops[i].k,drops[i].v);
    end
end

--销毁奖励UI图片
function My:ClearRwdCells()
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

function My:Dispose()
    self.isOpen = false;
    self:ClearRwdCells();
    GO.Destroy(self.root.gameObject);
end