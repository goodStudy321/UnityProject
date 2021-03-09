TempleMgr={Name="TempleMgr"}
local My = TempleMgr
local prv = {}
My.eTempleStBtn = Event();
My.eStreakSuc=Event();
My.eRed= Event();
function My:Init( )
    My.canSend=false;
    My.cansalara=true;
    My.isError=true
    self:AddLsnr()
end
--刷新btn状态
My.eBtnTrue=Event();
My.eshut=Event();
function My:AddLsnr()
    ProtoLsnr.AddByName("m_family_battle_temple_toc",prv.SetModelInfo)
    ProtoLsnr.AddByName("m_family_battle_salary_toc",prv.getRwdError)
    ProtoLsnr.AddByName("m_family_battle_cv_reward_toc",prv.stkRwd)
    ProtoLsnr.AddByName("m_family_battle_ecv_reward_toc",prv.shtRwd)
    ProtoLsnr.AddByName("m_family_refresh_bt_info_toc",prv.UpdateValue)
    ProtoLsnr.AddByName("m_family_battle_salary_update_toc",prv.Updatebtn)
    TempleMgr.eRed:Add(My.TempleSetRed);
end

-- function My.IsOpen(  )
    -- if ActivityTemp["149"].lv==nil or User.instance.MapData.Level==nil  then
    --     return false
    -- end
    -- return ActivityTemp["149"].lv>=User.instance.MapData.Level
--     return true
-- end

function My.TempleSetRed(bool)
    local open = OpenMgr:IsOpen(63)
    if open  ==false then
        return;
    end
    if bool then
      SystemMgr:ShowActivity(ActivityMgr.ZZSD)
    else
      SystemMgr:HideActivity(ActivityMgr.ZZSD)
    end
end

function prv.Updatebtn( )
    My.canSend=true;
    My.eBtnTrue();
    FamilyMgr:RedTempDrop( )
end
--发送薪水
function My.toSend()
  local msg = ProtoPool.Get("m_family_battle_salary_tos")
  ProtoMgr.Send(msg)
end
--发送连胜k=连胜排名v=连胜次数
function My.toSendStreak(id,kv)
    if id==nil then
        UITip.Log("该成员已不在道庭");
        return;
    end
    local msg = ProtoPool.Get("m_family_battle_cv_reward_tos")
    msg.role_id=id
    msg.reward.id=kv.id
    msg.reward.val=kv.val
    ProtoMgr.Send(msg)
end
--发送中断
function My.toSendShut(id)
    local msg = ProtoPool.Get("m_family_battle_ecv_reward_tos")
    msg.role_id=id
    ProtoMgr.Send(msg)
end
--设置神殿信息
function prv.SetModelInfo(msg)
    My.modelList={}
    if  msg==nil or msg.list==nil then
        return
    end
    local mg = msg.list
    for i=1,#mg do
        My.modelList[mg[i].rank]=mg[i]
    end
end
--获取神殿信息
function My.GetModelInfo()
    return My.modelList
end

--得到俸禄
function prv.getRwdError(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
    else
        My.cansalara=false     
        UITip.Log("领取成功")
        My.canSend=false;
        My.eTempleStBtn()  
        FamilyMgr:RedTempDrop( )
    end
end
--连胜分配
function prv.stkRwd(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
        My.isError=true
    else
        UITip.Log("分配成功")
        My.eStreakSuc();
        My.isError=false
    end
end
--终结分配
function prv.shtRwd( msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
        My.isError=true
    else
        UITip.Log("分配成功")
    end
end
--得到自己帮派信息
function My.GetFmlInfo()
    My.FmlInfo=FamilyMgr:GetTempleInfo()
    return My.FmlInfo
end
--刷新数据
function prv.UpdateValue(msg )
    FamilyMgr:SetTempleInfo(msg)
    My.eshut();
end

function My:Clear( )
    My.canSend=false;
    My.isError=true
    My.modelList=nil
    My.cansalara=true;
end
return My