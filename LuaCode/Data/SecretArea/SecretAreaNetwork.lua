--region 
--
--此文件由[HS]创建生成

SecretAreaNetwork = {Name = "SecretAreaNetwork"}
local M = SecretAreaNetwork

function M.Init()
	M.AddProto()
end

function M.AddProto()
	M.ProtoHandler(ProtoLsnr.Add)
end

function M.RemoveProto()
	M.ProtoHandler(ProtoLsnr.Remove)
end

function M.ProtoHandler(Lsnr)
    Lsnr(24802, M.ResqRoleInfo)
    Lsnr(24804, M.ResqCollectInfo)
    Lsnr(24806, M.ResqMoveNum)
    Lsnr(24808, M.ResqMoveLogs)
    Lsnr(24810, M.ResqGoodsUpdate)
    Lsnr(24812, M.ResqMapCellUpdate)
    Lsnr(24814, M.ResqPlunderUpdate)
    Lsnr(24816, M.ResqMapCellSingeUpdate)
    Lsnr(24824, M.ResqShift)
    Lsnr(24826, M.ResqPlunder)
    Lsnr(24828, M.ResqInspire)
    Lsnr(24830, M.ResqTakeOut)	
end
--[[######################################]]--
--开面板数据返回
function M.ResqRoleInfo(msg)
    if not ProtoMgr.CheckErr(msg.err_code) then return end
    SecretAreaMgr.UpdateInfo(msg)
end

--采集数据
function M.ResqCollectInfo(msg)
    SecretAreaMgr.UpdateCollectInfo(msg.gather_num, 
        msg.gather_stop_time, msg.is_family_add,true)
end

--移动剩余次数更新
function M.ResqMoveNum(msg)
    SecretAreaMgr.UpdateMoveInfo(msg.shift_num, true)
end

--历史移动记录
function M.ResqMoveLogs(msg)
    SecretAreaMgr.UpdateCellsInfo(msg.shift_history, true)
end

--获得奖励更新
function M.ResqGoodsUpdate(msg)
    SecretAreaMgr.UpdateGoodsList(msg.goods_list)
end

--更新格子信息
function M.ResqMapCellUpdate(msg)
    SecretAreaMgr.UpdateNightRoundList(msg.lattice, true)
end

--单个格子数据更新
function M.ResqMapCellSingeUpdate(msg)
    SecretAreaMgr.UpdateNightRound(msg.lattice, true)
end

--拦截日志更新
function M.ResqPlunderUpdate(msg)
    SecretAreaMgr.UpdatePlunderHistrory(msg.add_plunder_history, true)
end

--移动返回
function M.ResqShift(msg)
    if not ProtoMgr.CheckErr(msg.err_code) then return end
    UITip.Log("移动成功")
end

--拦截返回
function M.ResqPlunder(msg)
    if not ProtoMgr.CheckErr(msg.err_code) then return end
    local status = msg.status --状态:0,失败;1:成功
    if status == 1 then
        UITip.Log("拦截成功!")
    else
        UITip.Log("拦截失败!")
    end
    SecretAreaMgr.UpdateMoveInfo(msg.shift_num, true)
end

--鼓舞返回
function M.ResqInspire(msg)
    local err = msg.err_code
    if(err==0)then
        local tp = msg.type
        if tp==0 then UITip.Log("鼓舞成功!")end --0:鼓舞返回 1:0点更新
        SecretAreaMgr.UpdateInspireNum(msg.inspire,true)
    else
        UITip.Log(GetError(err))
    end
end

--挖矿，取出资源
function M.ResqTakeOut(msg)
    if not ProtoMgr.CheckErr(msg.err_code) then return end
    UITip.Log("成功取出")
    SecretAreaMgr.UpdateGoodsList()
end

--[[#############################################################]]--
--打开面板请求
function M.ReqRoleInfo()
    local msg = ProtoPool.GetByID(24801)
    ProtoMgr.Send(msg)
end

--请求移动
function M.ReqShift(new_x,new_y)
    local msg = ProtoPool.GetByID(24823)
    msg.new_x=new_x
    msg.new_y=new_y
    ProtoMgr.Send(msg)
end

--请求拦截
function M.ReqPlunder(object_id)
    local msg = ProtoPool.GetByID(24825)
    msg.object_id=object_id
    ProtoMgr.Send(msg)
end

--请求鼓舞
function M.ReqInspire()
    local msg = ProtoPool.GetByID(24827)
    ProtoMgr.Send(msg)
end

--挖矿，取出资源
function M.ReqTakeOut()
    local msg = ProtoPool.GetByID(24829)
    ProtoMgr.Send(msg)
end

--[[#############################################################]]--
function M:Clear()
	--self:RemoveProto()
end

return M