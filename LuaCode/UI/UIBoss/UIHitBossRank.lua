UIHitBossRank=Super:New{Name="UIHitBossRank"};
local My = UIHitBossRank;

local Gbj = {};

function My:Init(root)
    local tip = self.Name;
    self.root=root;
    local TFC = TransTool.FindChild;
    local CG = ComTool.Get;
    self.grid = CG(UIGrid,root,"sv/Grid",tip);
    self.PlayRankItem=TFC(root,"sv/Grid/PlayRankItem",tip);
    soonTool.setPerfab(self.PlayRankItem,"PlayRankItem");
    self:lsnr("Add");

    self.Timer = ObjPool.Get(DateTimer);
	self.Timer.complete:Add(self.timeOver, self);
end

function My:lsnr(fun )
    NetBoss.eRank[fun](NetBoss.eRank, self.Creat,self);
end

function My:Creat( )
    soonTool.AddList(Gbj,"PlayRankItem",true);
    local nr = NetBoss.ranklst;
    for k,v in ipairs(nr) do
        local go = soonTool.Get("PlayRankItem");
        My.doInfo(go,v);
        table.insert(Gbj,go);
        -- go.transform.parent=self.grid.transform;
    end
    self.grid:Reposition();
    self:SetTime();
end

function My:SetTime()
	if self.Timer == nil then
		return;
	end
    self.Timer:Reset();
    self.Timer.seconds =10;
	self.Timer:Start();
end

function My.doInfo(go,v)
    local root = go.transform
    local TFC = TransTool.FindChild;
    local CG = ComTool.Get;
    local name = CG(UILabel,root,"name");
    local hit = CG(UILabel,root,"hit");
    local rank = CG(UILabel,root,"rank");
    local bg = CG(UISprite,root,"rank/Bg");
    local bgGo = bg.transform.gameObject;
    name.text=v.role_name;
    rank.text=v.rank;
    local dam =  math.NumToStrCtr(v.damage);
    iTrace.Log("dam= "..dam);
    hit.text=dam;
    if v.rank<4 then
        bgGo:SetActive(true);
        if v.rank==1 then
            bg.spriteName="rank_flat_01";
        elseif v.rank==2 then
            bg.spriteName="rank_flat_02";
        elseif v.rank==3 then
            bg.spriteName="rank_flat_03";
        end
        else
        bgGo:SetActive(false); 
    end
    -- bgGo.name="Bg";
    go.name=v.rank;
end

function My:timeOver( )
    soonTool.AddList(Gbj,"PlayRankItem",true);
    soonTool.ClearList(NetBoss.ranklst);
end

function My:Clear( )
    self:timeOver();
    self:lsnr("Remove");
    soonTool.DesGo("PlayRankItem");
    if self.Timer==nil then
        return
    end
	self.Timer:AutoToPool();
	self.Timer = nil;
end

return My;