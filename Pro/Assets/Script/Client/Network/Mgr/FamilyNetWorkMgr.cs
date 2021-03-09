using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;


public partial class NetworkMgr
{
#region 事件
    public static void AddFamilyListener()
    {
        //NetworkListener.Add<m_family_create_toc>(RespFamilyCreate);
        //NetworkListener.Add<m_family_invite_toc>(RespFamilyInvite);
        //NetworkListener.Add<m_family_invite_reply_toc>(RespFamilyInviteReply);
        //NetworkListener.Add<m_family_apply_toc>(RespFamilyApply);
        //NetworkListener.Add<m_family_apply_reply_toc>(RespFamilyApplyReply);
        //NetworkListener.Add<m_family_admin_toc>(RespFamilyAdmin);
        //NetworkListener.Add<m_family_kick_toc>(RespFamilyKick);
        //NetworkListener.Add<m_family_leave_toc>(RespFamilyLeave);
        //NetworkListener.Add<m_family_config_toc>(RespFamilyConfig);
        //NetworkListener.Add<m_family_info_toc>(RespFamilyInfo);
        //NetworkListener.Add<m_family_info_update_toc>(RespFamilyInfoUpdate);
        //NetworkListener.Add<m_family_member_update_toc>(RespFamilyMemberUpdate);
        //NetworkListener.Add<m_family_apply_update_toc>(RespFamilyApplyUpdate);
        //NetworkListener.Add<m_family_brief_toc>(RespFamilyBrief);
        //NetworkListener.Add<m_family_depot_update_toc>(RespFamilyDepotUpdate);
        //NetworkListener.Add<m_family_donate_toc>(RespFamilyDonate);
        //NetworkListener.Add<m_family_del_depot_toc>(RespFamilyDelDonate);
        //NetworkListener.Add<m_family_exchange_depot_toc>(RespFamilyExcDonate);
        //NetworkListener.Add<m_family_depot_log_update_toc>(RespFamilyDepotLog);
        //NetworkListener.Add<m_family_skill_toc>(RespFamilySkillInfo);
    }

    public static void RemoveFamilyListener()
    {
        //NetworkListener.Remove<m_family_create_toc>(RespFamilyCreate);
        //NetworkListener.Remove<m_family_invite_toc>(RespFamilyInvite);
        //NetworkListener.Remove<m_family_invite_reply_toc>(RespFamilyInviteReply);
        //NetworkListener.Remove<m_family_apply_toc>(RespFamilyApply);
        //NetworkListener.Remove<m_family_apply_reply_toc>(RespFamilyApplyReply);
        //NetworkListener.Remove<m_family_admin_toc>(RespFamilyAdmin);
        //NetworkListener.Remove<m_family_kick_toc>(RespFamilyKick);
        //NetworkListener.Remove<m_family_leave_toc>(RespFamilyLeave);
        //NetworkListener.Remove<m_family_config_toc>(RespFamilyConfig);
        //NetworkListener.Remove<m_family_info_toc>(RespFamilyInfo);
        //NetworkListener.Remove<m_family_info_update_toc>(RespFamilyInfoUpdate);
        //NetworkListener.Remove<m_family_member_update_toc>(RespFamilyMemberUpdate);
        //NetworkListener.Remove<m_family_apply_update_toc>(RespFamilyApplyUpdate);
        //NetworkListener.Remove<m_family_brief_toc>(RespFamilyBrief);
        //NetworkListener.Remove<m_family_depot_update_toc>(RespFamilyDepotUpdate);
        //NetworkListener.Remove<m_family_donate_toc>(RespFamilyDonate);
        //NetworkListener.Remove<m_family_del_depot_toc>(RespFamilyDelDonate);
        //NetworkListener.Remove<m_family_exchange_depot_toc>(RespFamilyExcDonate);
        //NetworkListener.Remove<m_family_depot_log_update_toc>(RespFamilyDepotLog);
        //NetworkListener.Remove<m_family_skill_toc>(RespFamilySkillInfo);
    }
    #endregion

    #region Client -> Server

    /// <summary>
    /// 请求创建帮派
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqCreateFamily(params object[] args)
    //{
    //    m_family_create_tos req = ObjPool.Instance.Get<m_family_create_tos>();
    //    string fn = Convert.ToString(args[0]);
    //    req.family_name = fn;
    //    NetworkClient.Send<m_family_create_tos>(req);

    //    iTrace.Log("LY", "Sent create family : " + fn);

    //    //p_family_member tFM = new p_family_member();
    //    //tFM.role_name = "我有一头小毛驴";
    //    //p_family_apply tFA = new p_family_apply();
    //    //p_family tF = new p_family();
    //    //tF.members.Clear();
    //    //tF.members.Add(tFM);
    //    //tF.apply_list.Clear();
    //    //tF.apply_list.Add(tFA);
    //    //EventMgr.Trigger("TestStruct", tF);
    //}

    /// <summary>
    /// 请求邀请加入帮派
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyInvite(params object[] args)
    //{
    //    m_family_invite_tos req = ObjPool.Instance.Get<m_family_invite_tos>();
    //    req.role_id = Convert.ToInt64(args[0]);
    //    NetworkClient.Send<m_family_invite_tos>(req);
    //}

    /// <summary>
    /// 请求邀请者加入帮派应答
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyInviteReply(params object[] args)
    //{
    //    m_family_invite_reply_tos req = ObjPool.Instance.Get<m_family_invite_reply_tos>();
    //    req.op_type = Convert.ToInt32(args[0]);
    //    req.role_id = Convert.ToInt64(args[1]);
    //    req.family_id = Convert.ToInt64(args[2]);
    //    NetworkClient.Send<m_family_invite_reply_tos>(req);
    //}

    /// <summary>
    /// 申请加入帮会
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyApply(params object[] args)
    //{
    //    m_family_apply_tos req = ObjPool.Instance.Get<m_family_apply_tos>();
    //    req.family_id = Convert.ToInt64(args[0]);
    //    NetworkClient.Send<m_family_apply_tos>(req);
    //}

    /// <summary>
    /// 请求回应申请加入帮派
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyApplyReply(params object[] args)
    //{
    //    m_family_apply_reply_tos req = ObjPool.Instance.Get<m_family_apply_reply_tos>();
    //    req.op_type = Convert.ToInt32(args[0]);

    //    req.role_ids.Clear();
    //    LuaInterface.LuaTable lt = args[1] as LuaInterface.LuaTable;
    //    if(lt == null || lt.Length <= 0)
    //    {
    //        iTrace.Error("LY", "Role ids is null !!! ");
    //        return;
    //    }
    //    for(int a = 1; a <= lt.Length; a++)
    //    {
    //        req.role_ids.Add(Convert.ToInt64(lt[a]));
    //    }
    //    if(lt != null)
    //        lt.Dispose();
    //    NetworkClient.Send<m_family_apply_reply_tos>(req);
    //}

    /// <summary>
    /// 请求帮派调整职位
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyAdmin(params object[] args)
    //{
    //    m_family_admin_tos req = ObjPool.Instance.Get<m_family_admin_tos>();
    //    req.role_id = Convert.ToInt64(args[0]);
    //    req.new_title = Convert.ToInt32(args[1]);
    //    NetworkClient.Send<m_family_admin_tos>(req);
    //}

    /// <summary>
    /// 请求开除成员
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyKick(params object[] args)
    //{
    //    m_family_kick_tos req = ObjPool.Instance.Get<m_family_kick_tos>();
    //    req.role_id = Convert.ToInt64(args[0]);
    //    NetworkClient.Send<m_family_kick_tos>(req);
    //}

    /// <summary>
    /// 请求离开帮派
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyLeave(params object[] args)
    //{
    //    m_family_leave_tos req = ObjPool.Instance.Get<m_family_leave_tos>();
    //    NetworkClient.Send<m_family_leave_tos>(req);
    //}

    /// <summary>
    /// 请求修改帮派设置
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyConfig(params object[] args)
    //{
    //    bool tbl1Null = (bool)args[0];
    //    bool tbl2Null = (bool)args[1];

    //    if(tbl1Null == true && tbl2Null == true)
    //    {
    //        return;
    //    }

    //    LuaInterface.LuaTable key1Tbl = args[2] as LuaInterface.LuaTable;
    //    LuaInterface.LuaTable val1Tbl = args[3] as LuaInterface.LuaTable;
    //    LuaInterface.LuaTable key2Tbl = args[4] as LuaInterface.LuaTable;
    //    LuaInterface.LuaTable val2Tbl = args[5] as LuaInterface.LuaTable;

    //    m_family_config_tos req = ObjPool.Instance.Get<m_family_config_tos>();
    //    req.kv_list.Clear();
    //    req.ks_list.Clear();
    //    if (key1Tbl != null)
    //    {
    //        for (int a = 1; a <= key1Tbl.Length; a++)
    //        {
    //            p_kv tKv = new p_kv();
    //            tKv.id = Convert.ToInt32(key1Tbl[a]);
    //            tKv.val = Convert.ToInt32(val1Tbl[a]);
    //            req.kv_list.Add(tKv);
    //        }
    //    }
    //    if (key2Tbl != null)
    //    {
    //        for (int a = 1; a <= key2Tbl.Length; a++)
    //        {
    //            p_ks tKs = new p_ks();
    //            tKs.id = Convert.ToInt32(key2Tbl[a]);
    //            tKs.str = Convert.ToString(val2Tbl[a]);
    //            req.ks_list.Add(tKs);
    //        }
    //    }
    //    NetworkClient.Send<m_family_config_tos>(req);

    //    if(key1Tbl != null)
    //        key1Tbl.Dispose();
    //    if (val1Tbl != null)
    //        val1Tbl.Dispose();
    //    if (key2Tbl != null)
    //        key2Tbl.Dispose();
    //    if (val2Tbl != null)
    //        val2Tbl.Dispose();
    //}

    /// <summary>
    /// 请求帮派简介信息
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyBrief(params object[] args)
    //{
    //    m_family_brief_tos req = ObjPool.Instance.Get<m_family_brief_tos>();
    //    req.from = Convert.ToInt32(args[0]);
    //    req.to = Convert.ToInt32(args[1]);
    //    NetworkClient.Send<m_family_brief_tos>(req);
    //}

    /// <summary>
    /// 提交帮派捐献
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyDonate(params object[] args)
    //{
    //    if (args == null || args.Length <= 0)
    //        return;

    //    LuaInterface.LuaTable donateTbl = args[0] as LuaInterface.LuaTable;
    //    if (donateTbl == null)
    //    {
    //        return;
    //    }

    //    m_family_donate_tos req = ObjPool.Instance.Get<m_family_donate_tos>();
    //    req.goods_list.Clear();

    //    for(int a = 1; a <= donateTbl.Length; a++)
    //    {
    //        req.goods_list.Add(Convert.ToInt32(donateTbl[a]));
    //    }
    //    NetworkClient.Send<m_family_donate_tos>(req);

    //    donateTbl.Dispose();
    //}

    /// <summary>
    /// 帮派删除装备
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyDelDepot(params object[] args)
    //{
    //    if (args == null || args.Length <= 0)
    //        return;

    //    LuaInterface.LuaTable donateTbl = args[0] as LuaInterface.LuaTable;
    //    if (donateTbl == null)
    //    {
    //        return;
    //    }

    //    m_family_del_depot_tos req = ObjPool.Instance.Get<m_family_del_depot_tos>();
    //    req.goods_list.Clear();

    //    for (int a = 1; a <= donateTbl.Length; a++)
    //    {
    //        req.goods_list.Add(Convert.ToInt32(donateTbl[a]));
    //    }
    //    NetworkClient.Send<m_family_del_depot_tos>(req);

    //    donateTbl.Dispose();
    //}

    /// <summary>
    /// 帮派兑换装备
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilyExcDepot(params object[] args)
    //{
    //    if (args == null || args.Length <= 0)
    //        return;

    //    m_family_exchange_depot_tos req = ObjPool.Instance.Get<m_family_exchange_depot_tos>();
    //    req.goods_id = Convert.ToInt32(args[0]);
    //    req.num = Convert.ToInt32(args[1]);
    //    NetworkClient.Send<m_family_exchange_depot_tos>(req);
    //}

    /// <summary>
    /// 帮派技能升级
    /// </summary>
    /// <param name="args"></param>
    //public static void ReqFamilySkillUpgrade(params object[] args)
    //{
    //    if (args == null || args.Length <= 0)
    //        return;

    //    m_family_skill_tos req = ObjPool.Instance.Get<m_family_skill_tos>();
    //    req.skill_id = Convert.ToInt32(args[0]);
    //    NetworkClient.Send<m_family_skill_tos>(req);
    //}

    #endregion

    #region Server -> Client

    /// <summary>
    /// 帮派信息，上线推送
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyInfo(object obj)
    //{
    //    iTrace.eWarning("LY", "Family info arrive !!! ");

    //    m_family_info_toc resp = obj as m_family_info_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_info_toc error !!! ");
    //        return;
    //    }

    //    p_family tFamilyInfo = resp.family_info;
    //    bool tIsNull = false;
    //    if (tFamilyInfo == null)
    //    {
    //        //iTrace.Error("LY", "p_family is null !!! ");
    //        tIsNull = true;
    //        //return;
    //    }
    //    User.instance.FamilyName = tFamilyInfo != null ? tFamilyInfo.family_name : "unknown";
    //    EventMgr.Trigger("RespFamilyInfo", tIsNull, tFamilyInfo, resp.integral, resp.skill_list);
    //}

    /// <summary>
    /// 帮派信息更新
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyInfoUpdate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family info update arrive !!! ");

    //    m_family_info_update_toc resp = obj as m_family_info_update_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_info_update_toc error !!! ");
    //        return;
    //    }

    //    bool isKvNull = (resp.kv_list == null || resp.kv_list.Count <= 0);
    //    EventMgr.Trigger("RespFamilyInfoUpdate", isKvNull, resp.kv_list);
    //}

    /// <summary>
    /// 创建帮派返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyCreate(object obj)
    //{
    //    //UITip.EditorLogWarning("创建帮派");
    //    iTrace.eWarning("LY", "Family create info arrive !!! ");

    //    m_family_create_toc resp = obj as m_family_create_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_create_toc error !!! ");
    //        return;
    //    }

    //    if(resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    p_family tFamilyInfo = resp.family_info;
    //    if(tFamilyInfo == null)
    //    {
    //        iTrace.Error("LY", "p_family is null !!! ");
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyCreate", tFamilyInfo);
    //}

    /// <summary>
    /// 邀请加入帮派返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyInvite(object obj)
    //{
    //    iTrace.eWarning("LY", "Family invite info arrive !!! ");

    //    m_family_invite_toc resp = obj as m_family_invite_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_invite_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }


    //}

    /// <summary>
    /// 邀请者加入帮派应答返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyInviteReply(object obj)
    //{
    //    iTrace.eWarning("LY", "Family invite reply info arrive !!! ");

    //    m_family_invite_reply_toc resp = obj as m_family_invite_reply_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_invite_reply_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyInviteReply", resp.op_type, resp.reply_role_id, resp.reply_role_name);
    //}

    /// <summary>
    /// 申请加入帮会返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyApply(object obj)
    //{
    //    iTrace.eWarning("LY", "Family apply info arrive !!! ");

    //    m_family_apply_toc resp = obj as m_family_apply_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_apply_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyApply");
    //}

    /// <summary>
    /// 回应申请加入帮派返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyApplyReply(object obj)
    //{
    //    iTrace.eWarning("LY", "Family apply reply info arrive !!! ");

    //    m_family_apply_reply_toc resp = obj as m_family_apply_reply_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_apply_reply_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyApplyReply", resp.op_type, resp.reply_role_id, resp.reply_role_name);
    //}

    /// <summary>
    /// 帮派调整职位返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyAdmin(object obj)
    //{
    //    iTrace.eWarning("LY", "Family admin info arrive !!! ");

    //    m_family_admin_toc resp = obj as m_family_admin_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_admin_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyAdmin", resp.role_id, resp.new_title);
    //}

    /// <summary>
    /// 开除成员返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyKick(object obj)
    //{
    //    iTrace.eWarning("LY", "Family kick info arrive !!! ");

    //    m_family_kick_toc resp = obj as m_family_kick_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_kick_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyKick", resp.role_id);
    //}

    /// <summary>
    /// 离开帮派返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyLeave(object obj)
    //{
    //    iTrace.eWarning("LY", "Family leave info arrive !!! ");

    //    m_family_leave_toc resp = obj as m_family_leave_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_leave_toc error !!! ");
    //        return;
    //    }

    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyLeave", resp.role_id);
    //}

    /// <summary>
    /// 修改帮派设置返回
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyConfig(object obj)
    //{
    //    iTrace.eWarning("LY", "Family config info arrive !!! ");

    //    m_family_config_toc resp = obj as m_family_config_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_config_toc error !!! ");
    //        return;
    //    }
    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    bool isKvNull = (resp.kv_list == null || resp.kv_list.Count <= 0);
    //    bool isKsNull = (resp.ks_list == null || resp.ks_list.Count <= 0);
    //    EventMgr.Trigger("RespFamilyConfig", isKvNull, isKsNull, resp.kv_list, resp.ks_list);
    //}
    
    /// <summary>
    /// 帮派成员加入、更新、退出推送
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyMemberUpdate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family member update info arrive !!! ");

    //    m_family_member_update_toc resp = obj as m_family_member_update_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_member_update_toc error !!! ");
    //        return;
    //    }
        
    //    EventMgr.Trigger("RespFamilyMemberUpdate", resp.del_member_id, resp.member);
    //}

    /// <summary>
    /// 帮派申请新加、更新、删除推送
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyApplyUpdate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family apply update info arrive !!! ");

    //    m_family_apply_update_toc resp = obj as m_family_apply_update_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_apply_update_toc error !!! ");
    //        return;
    //    }

    //    List<long> delIds = new List<long>();
    //    for(int a = 0; a < resp.del_apply_ids.Count; a++)
    //    {
    //        delIds.Add(resp.del_apply_ids[a]);
    //    }
    //    bool newData = resp.apply != null;
    //    bool delNull = delIds.Count <= 0;

    //    EventMgr.Trigger("RespFamilyApplyUpdate", newData, resp.apply, delNull, delIds);
    //}

    /// <summary>
    /// 帮派申请新加、更新、删除推送
    /// </summary>
    /// <param name="obj"></param>
    //private static void RespFamilyBrief(object obj)
    //{
    //    iTrace.eWarning("LY", "Family brief info arrive !!! ");

    //    m_family_brief_toc resp = obj as m_family_brief_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_brief_toc error !!! ");
    //        return;
    //    }

    //    List<p_family_brief> briefList = resp.briefs;
    //    bool isNull = ( briefList == null || briefList.Count <= 0);

    //    EventMgr.Trigger("RespFamilyBrief", isNull, briefList, resp.all_num);
    //}

    /// <summary>
    /// 帮派仓库更新推送
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilyDepotUpdate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family depot update arrive !!! ");

    //    m_family_depot_update_toc resp = obj as m_family_depot_update_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_depot_update_toc error !!! ");
    //        return;
    //    }

    //    bool hasUpdate = resp.update_goods != null;
    //    bool hasDel = resp.del_goods != null;

    //    EventMgr.Trigger("RespFamilyDepotUpdate", hasUpdate, resp.update_goods, hasDel, resp.del_goods);
    //}

    /// <summary>
    /// 帮派贡献结果返回
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilyDonate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family donate arrive !!! ");

    //    m_family_donate_toc resp = obj as m_family_donate_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_donate_toc error !!! ");
    //        return;
    //    }
    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyDonate", resp.integral);
    //}

    /// <summary>
    /// 帮派贡献结果返回
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilyDelDonate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family delete donate arrive !!! ");

    //    m_family_del_depot_toc resp = obj as m_family_del_depot_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_del_depot_toc error !!! ");
    //        return;
    //    }
    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyDelDonate");
    //}

    /// <summary>
    /// 帮派兑换结果返回
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilyExcDonate(object obj)
    //{
    //    iTrace.eWarning("LY", "Family exchange donate arrive !!! ");

    //    m_family_exchange_depot_toc resp = obj as m_family_exchange_depot_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_exchange_depot_toc error !!! ");
    //        return;
    //    }
    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyExcDonate", resp.integral);
    //}

    /// <summary>
    /// 帮会仓库日志推送
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilyDepotLog(object obj)
    //{
    //    iTrace.eWarning("LY", "Family depot log arrive !!! ");

    //    m_family_depot_log_update_toc resp = obj as m_family_depot_log_update_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_depot_log_update_toc error !!! ");
    //        return;
    //    }
    //    if (resp.depot_log == null || resp.depot_log.Count <= 0)
    //    {
    //        iTrace.Error("LY", "depot_log is null !!! ");
    //        //UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilyDepotLog", resp.depot_log);
    //}

    /// <summary>
    /// 帮会仓库日志推送
    /// </summary>
    /// <param name="obj"></param>
    //public static void RespFamilySkillInfo(object obj)
    //{
    //    iTrace.eWarning("LY", "Family skill info arrive !!! ");

    //    m_family_skill_toc resp = obj as m_family_skill_toc;
    //    if (resp == null)
    //    {
    //        iTrace.Error("LY", "m_family_skill_toc error !!! ");
    //        return;
    //    }
    //    if (resp.err_code > 0)
    //    {
    //        iTrace.Error("LY", ErrorCodeMgr.GetError(resp.err_code));
    //        UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    //        return;
    //    }

    //    EventMgr.Trigger("RespFamilySkill", resp.skill_list);
    //}

    

    #endregion
}
