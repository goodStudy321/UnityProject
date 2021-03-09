--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 1/24/2019, 5:12:32 PM
--=============================================================================

UITabMgr = {Name = "UITabMgr"}

local My = UITabMgr

--索引字典
--k:UI名称,v:分页索引配置
My.cfgDic = {}

--索引字典
--k:UI名称,v:分页索引
My.idxDic = {}


--通过ui分页配置ID打开指定分页
--id(number):分页配置id
function My.OpenByCfg(id)
    local cfg = BinTool.Find(UITabCfg, id)
    if cfg then
        local name = cfg.ui
        local t1 = cfg.t1 or 0
        local t2 = cfg.t2 or 0
        local t3 = cfg.t3 or 0
        local t4 = cfg.t4 or 0
        local ui = UIMgr.Get(name)

        --// LY add begin
        local pSysId = cfg.psysid or 0;
        local pUiId = cfg.puiid or 0;
        if pSysId > 0 and OpenMgr:IsOpen(pSysId) == false then
            UITabMgr.OpenByCfg(pUiId);
            return;
        end
        --// LY add end

        local needOpen = true
        if ui then
            if ui.active == 1 then
                ui:OpenTabByIdx(t1, t2, t3, t4)
                needOpen = false 
            end
        end
        if needOpen then
            My.cfgDic[name] = cfg
            local ui = UIFty.Create(name)
            ui:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
            UIMgr.Open(name, My.OpenByCfgCb)
        end
    else
        iTrace.Error("Loong","no id:", id, ", in UITabCfg")
    end
end

--打开指定分页索引的回调
function My.OpenByCfgCb(name)
    My.OpenCb(name,My.cfgDic)
end

function My.OpenByIdx(name,t1, t2 ,t3, t4)
    t1 = t1 or 0
    t2 = t2 or 0
    t3 = t3 or 0
    t4 = t4 or 0
    local ui = UIMgr.Get(name)
    local needOpen = true
    if ui then
        if ui.active == 1 then
            ui:OpenTabByIdx(t1, t2, t3, t4)
            needOpen = false 
        end
    end
    if needOpen then
        local cfg = My.idxDic[name]
        if cfg == nil then 
            cfg = {}
            My.idxDic[name] = cfg
        end
        cfg.t1 = t1
        cfg.t2 = t2
        cfg.t3 = t3
        cfg.t4 = t4
        My.idxDic[name] = cfg
        local ui = UIFty.Create(name)
        ui:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
        UIMgr.Open(name, My.OpenByIdxCb)
    end
end

function My.OpenByIdxCb(name)
    My.OpenCb(name,My.idxDic)
end


function My.OpenCb(name, dic)
    local ui = UIMgr.Get(name)
    if ui then 
        local cfg = dic[name]
        local t1 = cfg.t1 or 0
        local t2 = cfg.t2 or 0
        local t3 = cfg.t3 or 0
        local t4 = cfg.t4 or 0
        ui:OpenTabByIdx(t1, t2, t3, t4)
    end
end

--跳转接口 (系统等级表)
--id        系统ID
--t1...     分页
--有特殊的开启条件时需要重写 GetSpecial 方法
function My.Jump(id, t1, t2, t3, t4)
    if id == nil then iTrace.Error("ID不能为空") return false end
    local isOpen = false
    local key = tostring(id)
    local cfg = ActivityTemp[key]
    if cfg == nil then iTrace.Error("找不到配置") return false end
    local type = cfg.type
    if StrTool.IsNullOrEmpty(cfg.ui) then
        local mgr = ActivityMgr
        if type == mgr.HDDT then--活动答题
            isOpen = My.IsOpen(type)
            if isOpen then SceneMgr:ReqPreEnter(30006, true, true) end
        end
        return
    end
    local ui = UIFty.Get(cfg.ui)
    if ui == nil then iTrace.Error("找不到对应UI") return false end
    local isSpecial = ui:GetSpecial(t1)
    isOpen = My.IsOpen(type)
    if isOpen then
        if isSpecial then
            if t1 == nil or t1 == 0 then
                UIMgr.Open(ui.Name)
            else
                My.OpenByIdx(ui.Name, t1, t2, t3, t4)
            end
            return true
        else
            -- iTrace.Error("条件不满足，不能开启")
        end
    end
    return false
end

--跳转接口 (系统开放表)
--id        系统ID
--t1...     分页
--有特殊的开启条件时需要重写 GetSpecial 方法
function My.JumpMenu(id, t1, t2, t3, t4)
    if id == nil then iTrace.Error("ID不能为空") return false end
    local isOpen = false
    local key = tostring(id)
    local cfg = SystemOpenTemp[key]
    if cfg == nil then iTrace.Error("找不到配置") return false end
    local list = cfg.jump
    if list[1] == nil then iTrace.Error("找不到UI，请检查配置") return false end
    local ui = UIFty.Get(list[1])
    if ui == nil then iTrace.Error("找不到对应UI") return false end
    local isOpen = OpenMgr:IsOpen(id)
    local isSpecial = ui:GetSpecial(t1)
    if isOpen then
        if isSpecial then
            if t1 == nil then
                UIMgr.Open(ui.Name)
            else
                My.OpenByIdx(ui.Name, t1, t2, t3, t4)
            end
            return true
        else
            -- iTrace.Error("条件不满足，不能开启")
        end
    else
        UITip.Log("系统未开启")
    end
    return false
end

--打开界面 (系统等级表)
function My.Open(list)
    local id = list[1] or 0
    local t1 = list[2] or 0
    local t2 = list[3] or 0
    local t3 = list[4] or 0
    local t4 = list[5] or 0
    local isJump = My.Jump(id, t1, t2, t3, t4)
    return isJump
end

--打开界面 (系统开放表)
function My.OpenMenu(list)
    local id = list[1] or 0
    local t1 = list[2] or 0
    local t2 = list[3] or 0
    local t3 = list[4] or 0
    local t4 = list[5] or 0
    local isJump = My.JumpMenu(id, t1, t2, t3, t4)
    return isJump
end

--判断是否已开启（系统类型）
function My.IsOpen(type)
    local isOpen = My.Pattern1(type) and My.Pattern3(type) and not My.Pattern2(type)
    return isOpen
end

--模式1（是否已开启）
function My.Pattern1(id)
    local state, lv = ActivityMgr:OpenState(id)
    if state then--开启
        return true
    elseif not state and lv ~= 0 then--未开启
        local str = string.format("%s级开启", UIMisc.GetLv(lv))
        UITip.Log(str)
    else--参数错误
        iTrace.Log("参数错误")
    end
    return false
end

--模式2（是否被屏蔽）
function My.Pattern2(id)
    local k,v = ActivityMgr:Find(id)
    local num = 0
    if v then
        local index = v.id
        if index == 129 then--充值图标
            num = ShieldEnum.RechargeIcon
        elseif index == 128 then--市场图标
            num = ShieldEnum.Market
        elseif index == 141 then--VIP商城图标
            num = ShieldEnum.VIPStore
        end
    else--不走系统等级表
        if id == 1001 then--VIP图标
            num = ShieldEnum.VIPIcon
        elseif id == 1002 then--VIP充值
            num = ShieldEnum.Recharge
        elseif id == 1003 then--VIP超值月卡
            num = ShieldEnum.MonthCard
        elseif id == 1004 then--VIP投资理财
            num = ShieldEnum.InvestFinance
        elseif id == 1005 then--VIP特权
            num = ShieldEnum.VIPPower
        elseif id == 1006 then--VIP投资
            num = ShieldEnum.VIPInvest
        elseif id == 1007 then--激活码
            num = ShieldEnum.ActivationCode
        elseif id == 1008 then--意见反馈
            num = ShieldEnum.Feedback
        end
    end
    return ShieldEntry.IsShield(num)
end

--模式3（是否有推送）
function My.Pattern3(id)
    local mgr = ActivityMgr
    local k, v = mgr:Find(id)
    if v then
        if mgr:CheckOpen(v) then
            return true
        end
    end
    UITip.Log("系统未开启")
    return false
end

return My