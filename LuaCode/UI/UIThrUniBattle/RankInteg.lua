require("UI/UIThrUniBattle/IntegInfo")
RankInteg = {Name = "RankInteg"}
local My = RankInteg
local TUB = ThrUniBattle
My.IntegInfos = {}

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
    self.OwnRank = CG(UILabel,trans,"OwnerInfo/PersonalRank",name,false);
    self.OwnInteg = CG(UILabel,trans,"OwnerInfo/PersonalInteg",name,false);
    self.InfoCell = TF(trans,"ScrollView/Grid/InfoCell",name);
    self.InfoCell:SetActive(false);

    UC(trans,"AllBtn",name,self.AllBtnC,self);
    UC(trans,"FoJieBtn",name,self.FoJieBtnC,self);
    UC(trans,"MoJieBtn",name,self.MoJieBtnC,self);
    UC(trans,"XianJieBtn",name,self.XianJieBtnC,self);
    UC(go.transform,"CloseBtn",name,self.CloseC,self);
    if self.campId == nil then
        self.campId = 4;
    end
    self:ShowInfo(self.campId);
end

function My:AllBtnC(go)
    self:ShowInfo(4);
end

function My:FoJieBtnC(go)
    self:ShowInfo(3);
end

function My:MoJieBtnC(go)
    self:ShowInfo(2);
end

function My:XianJieBtnC(go)
    self:ShowInfo(1);
end

function My:ShowInfo(campId)
    self.campId = campId;
    self:HideIntegs();
    local ownerId = tostring(User.MapData.UID);
    local rank = TUB.ranks[ownerId];
    if rank ~= nil then
        self:SHowOwnerInfo(rank.rank,rank.score);
    end

    local index = 1;
    for k,v in pairs(TUB.ranks) do
        if campId == v.campId or campId == 4 then
            local info = My.IntegInfos[k];
            if info == nil then
                info = IntegInfo:New();
                info:Open(self.InfoCell,v,index);
                My.IntegInfos[k] = info;
            else
                info:SetData(v,index);
                info:SetActive(true);
            end
            index = index + 1;
        end
    end
    self.UITable:Reposition();
end

function My:SHowOwnerInfo(rank,integral)
    self.OwnRank.text = string.format("第%s名", tostring(rank));
    self.OwnInteg.text = string.format("%s分",tostring(integral));
end

function My:HideIntegs()
    for k,v in pairs(My.IntegInfos) do
        v:SetActive(false);
    end
end

function My:ClearIntegs()
    for k,v in pairs(My.IntegInfos) do
        v:Dispose();
        TableTool.ClearUserData(v);
        My.IntegInfos[k] = nil;
    end
end

function My:CloseC(go)
    if self.root ~= nill then
        self.root.gameObject:SetActive(false);
    end
    self:ClearIntegs();
end