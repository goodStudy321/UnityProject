require("UI/UIThrUniBattle/RewardInfo")
RankRwd = {Name = "RankRwd"}
local My = RankRwd
local TUB = ThrUniBattle
My.RewardInfos = {}

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Open(go)
    go:SetActive(true);
    local trans = go.transform;
    self.root = trans;
    local name = go.name;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    
    self.UITable = CG(UITable,trans,"ScrollView/Grid",name,false);
    self.InfoCell = TF(trans,"ScrollView/Grid/InfoCell",name);
    self.InfoCell:SetActive(false);

    UC(trans,"CloseBtn",name,self.CloseC,self);

    self:ShowRankRwd();
end

function My:ShowRankRwd()
    for k,v in pairs(TUB.ranks) do
        local info = My.RewardInfos[k];
        if info == nil then
            info = RewardInfo:New();
            info:Open(self.InfoCell,v);
            My.RewardInfos[k] = info;
        else
            info:SetData(v);
            info:SetActive(true);
        end
    end
    self.UITable:Reposition();
end

function  My:ClearRwdInfos()
    for k,v in pairs(My.RewardInfos) do
        v:Dispose();
        TableTool.ClearUserData(v);
        My.RewardInfos[k] = nil;
    end
end

function My:CloseC(go)
    if self.root ~= nil then
        self.root.gameObject:SetActive(false);
    end
    self:ClearRwdInfos();
end