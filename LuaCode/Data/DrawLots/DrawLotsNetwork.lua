--[[
上上签协议
]]
DrawLotsNetwork={Name="DrawLotsNetwork"}
local My = DrawLotsNetwork
local GetError = ErrorCodeMgr.GetError
My.eInfo = Event()

--添加事件
function My.AddLnsr()
    local Add = ProtoLsnr.Add
    Add(24900, My.ResqTokenInfo)
    Add(24902, My.ResqPray)
end

--幸运上上签上线推送
function My.ResqTokenInfo(msgs)
    local lv = msgs.level
    local remainNum = msgs.remain_num
    local bigReward = msgs.big_reward
    local configIndex=msgs.config_index
    DrawLotsMgr.lv=lv
    DrawLotsMgr.remainNum=remainNum
    DrawLotsMgr.bigReward=bigReward
    DrawLotsMgr.configIndex=configIndex
    --DrawLotsNetwork.eInfo()
end

--请求抽签
function My.ReqPray(times)
    local msg = ProtoPool.GetByID(24901)
    msg.times=times
    ProtoMgr.Send(msg)
end

--请求抽签返回
function My.ResqPray(msgs)
    local err = msgs.err_code
    if(err==0)then
		local lv = msgs.level
        local remainNum = msgs.remain_num
        local bigReward = msgs.big_reward
        local reward_index_list = msgs.reward_index_list
        DrawLotsMgr.lv=lv
        DrawLotsMgr.remainNum=remainNum
        DrawLotsMgr.bigReward=bigReward

        local List = {}
        for i,v in ipairs(reward_index_list) do
            table.insert( List, v)
        end
        DrawLotsMgr.eUp(List)
	else
		UITip.Log(GetError(err))
	end
end