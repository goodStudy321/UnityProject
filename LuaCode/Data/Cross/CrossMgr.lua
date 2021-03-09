CrossMgr = { Name = "CrossMgr" }
local My = CrossMgr

--跨服
My.crossOpen=false;
--下一次分配时间
My.nextTime = 0;
My.eCross=Event();
function My:Init(  )
    self:AddLsnr();
end
function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName;
    PA("m_cross_status_toc",self.OpenCross,self);
end
--是否开启跨服
function My:OpenCross( msg )
    My.crossOpen=msg.is_connected;
    My.nextTime = msg.next_match_time;
    self.eCross(My.crossOpen);
end

function My:Clear(  )
   
end

return My;