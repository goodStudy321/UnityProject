PkRkItem = {Name = "PkRkItem"}
local My = PkRkItem;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init(go,parent,pos)
    self.root = self:CloneGo(go,parent,pos);
    local root = self.root.transform;
    local name = root.name;
    local CG = ComTool.Get;
    local CGS = ComTool.GetSelf;
    self.Bg = CGS(UISprite,root,name);
    self.Rank = CG(UILabel,root,"Rank",name,false);
    self.RankIcon = CG(UISprite,root,"Rank/RankIcon",name,false);
    self.RankBg = CG(UISprite,root,"Rank/RankBg",name,false);
    self.RoleName = CG(UILabel,root,"RoleName",name,false);
    self.Dan = CG(UILabel,root,"DanLbl",name,false);
    self.Score = CG(UILabel,root,"Score",name,false);
end

function My:CloneGo(go,parent,pos)
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = parent;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(false);
    if pos ~= nil then
        root.transform.localPosition = pos;
    end
    return root;
end

--设置背景图
function My:SetBg(index)
    if index == nil then
        return;
    end
    local num,lnum = math.modf(index/2);
    if lnum == 0 then
        self.Bg.spriteName = "";
    else
        self.Bg.spriteName = "rank_info_b";
    end
end

--设置排名数据
function My:SetData(rank,roleName,score,isOwner)
    if isOwner == false then
        self:SetBg(rank);
    end
    self.root:SetActive(true);
    local rankStr = string.format( "%02d",rank);
    self.root.name = rankStr;
    self.Rank.text = tostring(rank);
    self.RoleName.text = roleName;
    self.Score.text = score;
    self:SetRankIcon(rank);
    self:SetDan(score);
end

--设置排名背景图标
function My:SetRankIcon(rank)
    local rankStr = "";
    local rankBg = "";
    if rank == 1 then
        rankStr = "rank_icon_1";
        rankBg = "rank_info_g";
    elseif rank == 2 then
        rankStr = "rank_icon_2";
        rankBg = "rank_info_b";
    elseif rank == 3 then
        rankStr = "rank_icon_3";
        rankBg = "rank_info_z";
    elseif rank > 3 and rank % 2 == 1 then
        rankBg = "ty_a19"
    end
    self.RankIcon.spriteName = rankStr;
    self.RankBg.spriteName = rankBg;
end

--设置段位名
function My:SetDan(score)
    local danInfo = UIPeak.GetDanInfoByScr(score);
    if danInfo == nil then
        return;
    end
    self.Dan.text = danInfo.danName;
end

function My:Clear()
    self.root.transform.parent = null;
    GO.Destroy(self.root);
    TableTool.ClearUserData(self);
end