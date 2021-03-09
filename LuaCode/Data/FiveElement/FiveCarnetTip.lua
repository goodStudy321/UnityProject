FiveCarnetTip={Name="FiveCarnetTip"}
local My = FiveCarnetTip

My.IsTipOpen=false
My.EnterMap=false
My.CopyEnterBeforIs23=false
function My.EnterMapRcd(  )
    My.EnterMap=true
    if FiveElmtMgr.curMaxCopyId==nil or FiveElmtMgr.curMaxCopyId==0 then
      return
    end
    local copyLv = FvElmntCfg[tostring(FiveElmtMgr.curMaxCopyId)].copyLv
    My.CopyEnterBeforIs23=copyLv==23
end

function My.OpenCheck(  )
    if (not My.IsTipOpen) and My.EnterMap and My.CopyEnterBeforIs23 and
        FiveElmtMgr.CanGoTip=="未集齐套装" and FiveElmtMgr.CanGoNxt==false then
        MsgBox.ShowYes("可通过扫荡本层BOSS关卡，集齐对应天机印，方可继续前往下一层五行幻境", My.YesCb,My, "确定");
        My.IsTipOpen=true
        My.EnterMap=false
        My.CopyEnterBeforIs23=false
        return true
    end
    return false
end
function My:YesCb(  )
    return
end

function My:Clear(  )
    My.IsTipOpen=false
    My.EnterMap=false
    My.CopyEnterBeforIs23=false
end


return My;