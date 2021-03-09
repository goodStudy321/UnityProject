GdAwardMgr={Name="GdAwardMgr"};
local My = GdAwardMgr
--领取状态
My.canGet=2;
--领取状态事件
My.eBtn=Event();

function My:Init( )
    -- self:lsnr();
    --如果换渠道没有填写一跑就报错 
    -- local id = User.instance.GameChannelId
    -- local info = GdRwd[id];
    -- if info==nil or info.rwd==nil then
    --    iTrace.Error("soon","H 好评配置表没有找到此gameChannelId数据 id= "..id)
    --    return
    -- end
end

function My:lsnr( )
    ProtoLsnr.AddByName("m_comment_status_toc",self.GetStation,self);
    ProtoLsnr.AddByName("m_comment_reward_toc",self.getRwdError,self);
end
--发送领取
function My:rwdSend()
    local msg = ProtoPool.Get("m_comment_reward_tos")
    ProtoMgr.Send(msg);
    self.canGet=2;
    self.eBtn();
end
--发送状态
function My:satnSend()
    local msg = ProtoPool.Get("m_comment_status_tos")
    ProtoMgr.Send(msg)
end
--得到状态
function My:GetStation(msg)
    self.canGet=msg.status;
    self.eBtn();
    -- LvAwardMgr:UpAction(4, self.canGet<2)
end
--是否领取成功
function My:getRwdError(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
    else
        UITip.Log("领取成功")
    end
end

function My:Clear( )

end
return My;