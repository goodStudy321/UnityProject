WBChgOwner = {Name = "WBChgOwner"}
local My = WBChgOwner;
My.eChgOwner = Event();

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName;
    PA("m_world_boss_change_owner_toc",self.ChgOwner,self)
end

function My:ChgOwner(msg)
    local beKilled = msg.old_owner_name;
    local newBlg = msg.new_owner_name;
    My.eChgOwner(beKilled,newBlg);
end