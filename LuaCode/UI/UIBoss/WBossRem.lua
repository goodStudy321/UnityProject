WBossRem = Super:New{Name="WBossRem"}
local My = WBossRem
My.LBlst={};
function My:Init(root)
    --常用工具
    local tip = "WBossRem"
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    self.grid=CG(UIGrid,root,"grid_grid",tip)
    self.info=TFC(root,"grid_grid/gbj_info",tip)
    soonTool.setPerfab(self.info,"bossLabSw");
    self:Creat();
end

function My:Creat(  )
    self:PutIn()
    local lst  = NetBoss.what3Boss;
    for i=1,#lst do
        local go = soonTool.Get ("bossLabSw")
        self:doOne(go,lst[i]);
        table.insert( self.LBlst, go )
    end
    self.grid:Reposition();
end



function My:PutIn(  )
    soonTool.AddList(self.LBlst,"bossLabSw",true);
end

function My:Clear()
    self:PutIn()
    soonTool.DesGo("bossLabSw")
    TableTool.ClearUserData(self);
end

return My
