IntegInfo = {}
local My = IntegInfo;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Open(go,rankInfo,index)
    local item = GO.Instantiate(go);
    item = item.transform;
    item.name = ActvHelper.RankToStr(rankInfo.rank);
    item.parent = go.transform.parent;
    item.localPosition = Vector3.zero;
    item.localScale = Vector3.one;
    self.root = item;
    local CG = ComTool.Get;
    self.RankLbl = CG(UILabel,item,"RankLbl",name,false);
    self.CellBg = CG(UISprite,item,"CellBg",name,false);
    self.NameLbl = CG(UILabel,item,"NameLbl",name,false);
    self.LevelLbl = CG(UILabel,item,"LevelLbl",name,false);
    self.IntegLbl = CG(UILabel,item,"IntegLbl",name,false);
    self.FightLbl = CG(UILabel,item,"FightLbl",name,false);
    self.NameLbl.text = rankInfo.roleName;
    self:SetData(rankInfo,index);
    self:SetActive(true);
end

--设置背景图
function My:SetBg(index)
    if self.CellBg == nil then
        return;
    end
    local num,lnum = math.modf(index/2);
    if lnum == 0 then
        self.CellBg.spriteName = "list_bg_1";
    else
        self.CellBg.spriteName = "list_bg_2";
    end
end

function My:SetActive(active)
    if self.root.gameObject.activeSelf == active then
        return;
    end
    self.root.gameObject:SetActive(active);
end

--设置数据
function  My:SetData(rankInfo,index)
    self:SetBg(index);
    self.RankLbl.text = tostring(rankInfo.rank);
    self.LevelLbl.text = tostring(rankInfo.level);
    self.IntegLbl.text = tostring(rankInfo.score);
    self.FightLbl.text = tostring(rankInfo.fightVal);
end

function My:Dispose()
    GO.Destroy(self.root.gameObject);
end