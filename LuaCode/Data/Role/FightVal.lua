FightVal = {Name = "FightVal"}
local My = FightVal;
My.eChgFv = Event();

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    EventMgr.Add("OnChangeFight",self.OnChgFV);
end

function My:RemoveLsnr()
    EventMgr.Remove("OnChangeFight",self.OnChgFV);
end

--更新战斗力
function My:OnChgFV()
    My.eChgFv();
end

function My:Clear()

end

function My:Dispose()
    self:RemoveLsnr();
end

return My;