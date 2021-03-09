MyFiveRankItem = Super:New{Name="MyFiveRankItem"}
local My = MyFiveRankItem
function My:Init(go)
    self.go=go
    self.root=go.transform
    --常用工具
    local tip = "MyFiveRankItem"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get

    self.bgSpr=CG(UISprite,root,"spr_bgSpr",tip)
    self.RankBg=CG(UISprite,root,"bg3",tip)
    self.rankLab=CG(UILabel,root,"lab_rankLab",tip)
    self.robLab=CG(UILabel,root,"lab_robLab",tip)
    self.nameLab=CG(UILabel,root,"lab_nameLab",tip)
    self.msgLab=CG(UILabel,root,"lab_msgLab",tip)

end

function My:UpInfo(msg,blMy )
    self.blMy=blMy
    self.rank=msg.rank
    if  self.rank~=nil and  self.rank~="未上榜" then
        self.go.name=tostring(tonumber(self.rank)+100)
    end
    self.rankLab.text=tostring(msg.rank)
    self.nameLab.text=msg.role_name
    self.robLab.text=msg.confine
    self:SetRankIcon(self.rank)
    self:setCopy( msg.copyId )
end

--设置排名背景图标
function My:SetRankIcon(rank)
    local rankStr = "";
    local rankBg = "";
    if rank=="未上榜" then
        rankBg = ""
    elseif rank == 1 then
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
    self.bgSpr.spriteName = rankStr;
    self.RankBg.spriteName = rankBg;
end

function My:setCopy( id )
    if id==0 then
        self.msgLab.text="无"
    end
    if FvElmntCfg[tostring(id)]==nil then
        return
    end
    local name = FvElmntCfg[tostring(id)].name
    self.msgLab.text=name
end

function My:Dispose()
    if self.blMy~=true then
       soonTool.Add(self.go,"FiveRankItem") 
    end
end

return My
