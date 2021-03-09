using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class AtcionDataRefresh
{
    [MenuItem("Developer/LJF/刷新动作编辑器数据 #%r")]
    private static void RefreshActionData()
    {
        if (!Application.isPlaying)
            return;
        Global.ActionSetupData = ActionHelper.GetActionSetupDataFromFile();
        UnitMgr.instance.RefreshUnitActionSetup();
    }

    [MenuItem("Developer/LJF/设置挂机")]
    private static void SetHangup()
    {
        if (!Application.isPlaying)
            return;
    }

    [MenuItem("Developer/LJF/上坐骑")]
    private static void PutOnMount()
    {
        if (!Application.isPlaying)
            return;
        NetPendant.RequestChangeMount(1);
        //PendantMgr.instance.PutOn(InputMgr.instance.mOwner, 3010001);
    }

    [MenuItem("Developer/LJF/下坐骑")]
    private static void TakeOffMount()
    {
        if (!Application.isPlaying)
            return;
        NetPendant.RequestChangeMount(0);
        //PendantMgr.instance.TakeOff(InputMgr.instance.mOwner, 3010001);
    }

    [MenuItem("Developer/LJF/角色死亡")]
    private static void RoleDead()
    {
        if (!Application.isPlaying)
            return;
        Phantom.Protocal.m_role_dead_toc roledead = new Phantom.Protocal.m_role_dead_toc();
        roledead.src_name = "who who who";
        roledead.normal_relive_time = 10;
        NetRevive.ResponeRoleDead(roledead);
    }

    [MenuItem("Developer/LJF/角色复活")]
    private static void RoleRevive()
    {
        if (!Application.isPlaying)
            return;
        Phantom.Protocal.m_role_relive_toc roleRevive = new Phantom.Protocal.m_role_relive_toc();
        roleRevive.err_code = 0;
        NetRevive.ResponeRoleRevive(roleRevive);
    }

    [MenuItem("Developer/LJF/保存资源 %q")]
    private static void SaveAssets()
    {
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
}
