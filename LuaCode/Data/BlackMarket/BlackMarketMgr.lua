BlackMarketMgr = {Name="BlackMarketMgr"}
local My = BlackMarketMgr

--剩余次数
My.lessTimes=0;
My.eLessChange=Event()
--可抽取道具集合
My.ItemLst={}
My.eItem=Event()
--抽取道具
My.BackItem={}
My.ebackItem=Event()

function My:Init()
    local PA =  ProtoLsnr.AddByName;
    PA("m_role_act_choose_info_toc",self.ChangeBack)   
    PA("m_role_act_choose_count_toc",self.LessChange)
    PA("m_role_act_choose_extract_toc",self.extractBack)   
end

function My.LessChange( msg )
    My.lessTimes=msg.count;
    -- iTrace.eError("soon1",My.lessTimes)
    My.eLessChange()
end

function My.extractBack( msg )
    if msg.err_code==0 then
        My.BackItem=msg.reward;
        My.lessTimes=msg.count;
        -- iTrace.eError("soon2",My.lessTimes)
        My.eLessChange()
        My.ebackItem()
    else
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end

function My.SendExtract( id )
    local msg = ProtoPool.Get("m_role_act_choose_extract_tos");
    msg.id=id
    ProtoMgr.Send(msg);
end

function My.ChangeBack( msg )
    if msg.err_code==0 then
     My.ItemLst=msg.goods_list;
     if #My.ItemLst~=12 then
        iTrace.eError("soon","后端发送数据不等于12")
         return
     end
     My.eItem()
    else
     UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
    end
end

function My.sendStart( )
    local msg = ProtoPool.Get("m_role_act_choose_info_tos");
    ProtoMgr.Send(msg);
end

function My:Clear()

end

return My
