SelectBoss = {Name="SelectBoss"}
local My = SelectBoss;
My.BossId = 0;

--设置选择BossId
function My:SetSelectBoss(bossId)
    My.BossId = bossId;
end

function My:Clear()
    My.BossId = 0;
end

function My:Dispose()
    self:Clear();
end