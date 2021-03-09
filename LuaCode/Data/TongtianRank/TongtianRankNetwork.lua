TongtianRankNetwork={Name="TongtianRankNetwork"}
local My = TongtianRankNetwork
local GetError = ErrorCodeMgr.GetError

function My.AddLnsr( ... )
    local Add = ProtoLsnr.Add
    --Add(24922, My.ResqUniverseFloor)
    Add(24924, My.ResqUniverseRank)
    Add(24926, My.ResqAdmire)
    Add(24928, My.ResqInfoAdmire)
end

-- --获取太虚通天塔最快&最低战力通关玩家
-- function My.ReqUniverseFloor(copy_id)
--     local msg = ProtoPool.GetByID(24921)
--     msg.copy_id=copy_id
--     ProtoMgr.Send(msg)
-- end

-- --获取太虚通天塔最快&最低战力通关玩家返回
-- function My.ResqUniverseFloor(msgs)
--     local fast_role_id = msgs.fast_role_id
--     local fast_role_name = msgs.fast_role_name
--     local fast_server_name = msgs.fast_server_name
--     local use_time = msgs.use_time
--     local power_role_id = msgs.power_role_id
--     local power_role_name = msgs.power_role_name
--     local power_server_name = msgs.power_server_name
--     local power = msgs.power

-- end

--获取太虚通天塔排行
function My.ReqUniverseRank()
    local msg = ProtoPool.GetByID(24923)
    ProtoMgr.Send(msg)
end

--获取太虚通天塔排行返回
function My.ResqUniverseRank(msgs)
    local universe_ranks = msgs.universe_ranks
    local best_three = msgs.best_three

    if universe_ranks then
        for i,v in ipairs(universe_ranks) do
            local data = {}
            data.rank=v.rank
            data.role_id=v.role_id
            data.role_name=v.role_name
            data.server_name=v.server_name
            data.confine_id=v.confine_id
            data.copy_id=v.copy_id
            data.use_time=v.use_time
            TongtianRankMgr.rankList[i]=data
        end
    end

    if best_three then
        for i,v in ipairs(best_three) do
            local data = {}
            data.rank=v.rank
            data.role_id=v.role_id
            data.role_name=v.role_name
            data.server_name=v.server_name
            data.copy_id=v.copy_id
            data.category=v.category
            data.sex=v.sex
            data.lv=v.level
            
            local sk = v.skin_list
            if sk then 
                local skinList = {}
                for i1,v1 in ipairs(sk) do
                    skinList[i1]=v1
                end
                data.skin_list=skinList
            end
            TongtianRankMgr.bestThreeList[i]=data
        end
    end
    TongtianRankMgr.UpRed()
    TongtianRankMgr.eData()
end

--膜拜
function My.ReqAdmire()
    local msg = ProtoPool.GetByID(24925)
    ProtoMgr.Send(msg)
end

--膜拜返回
function My.ResqAdmire(msgs)
    local err = msgs.err_code
    if(err==0)then
        local admire_times = msgs.admire_times
        TongtianRankMgr.admire_times=admire_times
        UITip.Log("敬畏之心油然而生，膜拜成功")
        TongtianRankMgr.UpRed()
        TongtianRankMgr.eAdmire()
    else
        UITip.Log(GetError(err))
    end
end

--上线膜拜次数推送
function My.ResqInfoAdmire(msgs)
    local admire_times = msgs.admire_times
    TongtianRankMgr.admire_times=admire_times
end

return My