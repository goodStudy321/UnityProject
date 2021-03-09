using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using Phantom.Protocal;
using System.Net;
using System.Threading;
using System.Net.Sockets;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;

using Lang = Phantom.Localization;

public partial class NetworkMgr
{
    public class ConnectData
    {
        public string host;

        public string ip;

        public int port;

        public Action<string> cb;


        public ConnectData(string host, int port, Action<string> cb)
        {
            this.host = host;
            this.port = port;
            this.cb = cb;
        }

        public ConnectData()
        {

        }
    }

    private static ConnectData data = new ConnectData();

    /// <summary>
    /// 准备进入场景
    /// </summary>
    public static bool IsLoadReady = false;
    /// <summary>
    /// 是否有场景资源
    /// </summary>
    public static bool IsHadResource = true;
    /// <summary>
    /// 请求进入场景id 重复请求进入相同的id return
    /// </summary>
    public static int ReqPreID = 0;
    /// <summary>
    /// 是否防沉迷   1：防沉迷
    /// </summary>
    public static int AntiIndex = 0;

    private static m_select_role_tos selectRole = null;

    #region 属性
    /// <summary>
    /// 一帧最大协议发送数量
    /// </summary>
    public static int SendProtoMax
    {
        get { return NetworkClient.SktSend.MaxSize; }
        set { NetworkClient.SktSend.MaxSize = (ushort)value; }
    }

    /// <summary>
    /// 一帧最大协议处理数量
    /// </summary>
    public static int RecvProtoMax
    {
        get { return NetworkClient.SktRecv.MaxSize; }
        set { NetworkClient.SktRecv.MaxSize = (ushort)value; }
    }
    #endregion

    #region 事件
    public static void AddListener()
    {
        EventMgr.Add(EventKey.AntiIndulge, AntiIndulge);
        NetworkListener.Add<m_auth_key_toc>(RespLogin);
        NetworkListener.Add<m_role_reconnect_toc>(ReConnectMgr.RespReConnect);
        NetworkListener.Add<m_pre_enter_toc>(RespPreEnter);
        NetworkListener.Add<m_enter_map_toc>(RespEnterScene);
        NetworkListener.Add<m_quit_map_toc>(RespQuitScene);
        NetworkListener.Add<m_map_slice_enter_toc>(RespMapSliceEnter);
        //NetworkListener.Add<m_function_list_toc>(RespFunctionList);
        NetworkListener.Add<m_map_actor_attr_change_toc>(NetAttr.RespPropertyUpdate);
        NetworkListener.Add<m_role_attr_change_toc>(NetAttr.RespPsnPro);
        NetworkListener.Add<m_system_hb_toc>(HeartBeat.RespHeartbeat);
        NetworkListener.Add<m_system_error_toc>(RespSystemErroer);
        NetworkListener.Add<m_create_role_toc>(RespCreate);
        NetworkListener.Add<m_select_role_toc>(RespSelect);
        NetworkListener.Add<m_del_role_toc>(RespDel);
        NetworkListener.Add<m_role_login_toc>(RespRoleLogin);
        //世界boss归属更新
        NetworkListener.Add<m_world_boss_owner_update_toc>(NetAttr.RespWBossOwner);

        //角色属性更新
        NetworkListener.Add<m_role_base_toc>(NetAttr.RespBaseProperty);
        //等级经验更新
        NetworkListener.Add<m_role_level_toc>(NetAttr.RespRoleLevelUpdate);
        //血量buff更新
        NetworkListener.Add<m_actor_info_change_toc>(NetAttr.RespActorInfoChangeUpdate);
        //移动信息
        NetworkListener.Add<m_move_point_toc>(NetMove.ResponeMove);
        NetworkListener.Add<m_stick_move_toc>(NetMove.ResponeStkMove);
        NetworkListener.Add<m_move_stop_toc>(NetMove.ResponeStopMove);
        NetworkListener.Add<m_move_sync_toc>(NetMove.ResponePosition);
        NetworkListener.Add<m_map_change_pos_toc>(NetMove.ResponeMoveRush);

        //技能
        NetworkListener.Add<m_role_skill_toc>(NetSkill.ResponseSkillOnline);
        NetworkListener.Add<m_skill_update_toc>(NetSkill.ResponseSkillUpdate);
        NetworkListener.Add<m_fight_prepare_toc>(NetSkill.ResponsePrepareSkill);
        NetworkListener.Add<m_fight_attack_toc>(NetSkill.ResponsePlaySkill);
        NetworkListener.Add<m_war_spirit_skill_toc>(NetSkill.RespSumRemove);
        NetworkListener.Add<m_skill_target_add_toc>(NetSkill.RespSkillTarAdd);
        NetworkListener.Add<m_skill_cd_reduce_toc>(NetSkill.RespSkillCDReduce);
        //buff
        NetworkListener.Add<m_actor_buff_change_toc>(NetBuff.ResponeBuff);
        NetworkListener.Add<m_buff_change_hp_toc>(NetBuff.ResponeBuffHpChange);
        //复活
        NetworkListener.Add<m_role_dead_toc>(NetRevive.ResponeRoleDead);
        NetworkListener.Add<m_role_relive_toc>(NetRevive.ResponeRoleRevive);
        //战斗模式
        NetworkListener.Add<m_change_pk_mode_toc>(NetFightInfo.ResponeChangeFightMode);

        //AddMissionListener();
        DropNetworkMgr.DropAddListener();

        //AddCopyListener();
        //AddWingListener();
        //AddFriendListener();
        AddFamilyListener();
        //AddTeamListener();
        //AddRankListener();
        CollectionMgr.AddLsnr();
        PendantMgr.instance.AddListener();
        NetWorldBoss.AddListener();
        OffLineBatMgr.AddSlOfflListener();
    }

    public static void RemoveListener()
    {
        EventMgr.Remove(EventKey.AntiIndulge, AntiIndulge);
        NetworkListener.Remove<m_auth_key_toc>(RespLogin);
        NetworkListener.Remove<m_role_reconnect_toc>(ReConnectMgr.RespReConnect);
        NetworkListener.Remove<m_pre_enter_toc>(RespPreEnter);
        NetworkListener.Remove<m_enter_map_toc>(RespEnterScene);
        NetworkListener.Remove<m_quit_map_toc>(RespQuitScene);
        NetworkListener.Remove<m_map_slice_enter_toc>(RespMapSliceEnter);
        //NetworkListener.Remove<m_function_list_toc>(RespFunctionList);
        NetworkListener.Remove<m_map_actor_attr_change_toc>(NetAttr.RespPropertyUpdate);
        NetworkListener.Remove<m_role_attr_change_toc>(NetAttr.RespPsnPro);
        NetworkListener.Remove<m_system_hb_toc>(HeartBeat.RespHeartbeat);
        NetworkListener.Remove<m_system_error_toc>(RespSystemErroer);
        NetworkListener.Remove<m_create_role_toc>(RespCreate);
        NetworkListener.Remove<m_select_role_toc>(RespSelect);
        NetworkListener.Remove<m_del_role_toc>(RespDel);
        //世界boss归属更新
        NetworkListener.Remove<m_world_boss_owner_update_toc>(NetAttr.RespWBossOwner);
        //角色属性更新
        NetworkListener.Remove<m_role_base_toc>(NetAttr.RespBaseProperty);
        //等级经验更新
        NetworkListener.Remove<m_role_level_toc>(NetAttr.RespRoleLevelUpdate);
        //血量buff更新
        NetworkListener.Remove<m_actor_info_change_toc>(NetAttr.RespActorInfoChangeUpdate);
        //移动信息
        NetworkListener.Remove<m_move_point_toc>(NetMove.ResponeMove);
        NetworkListener.Remove<m_stick_move_toc>(NetMove.ResponeStkMove);
        NetworkListener.Remove<m_move_stop_toc>(NetMove.ResponeStopMove);
        NetworkListener.Remove<m_move_sync_toc>(NetMove.ResponePosition);
        NetworkListener.Remove<m_map_change_pos_toc>(NetMove.ResponeMoveRush);
        //技能
        NetworkListener.Remove<m_role_skill_toc>(NetSkill.ResponseSkillOnline);
        NetworkListener.Remove<m_skill_update_toc>(NetSkill.ResponseSkillUpdate);
        NetworkListener.Remove<m_fight_attack_toc>(NetSkill.ResponsePlaySkill);
        NetworkListener.Remove<m_war_spirit_skill_toc>(NetSkill.RespSumRemove);
        NetworkListener.Remove<m_skill_target_add_toc>(NetSkill.RespSkillTarAdd);
        NetworkListener.Remove<m_skill_cd_reduce_toc>(NetSkill.RespSkillCDReduce);
        //buff
        NetworkListener.Remove<m_actor_buff_change_toc>(NetBuff.ResponeBuff);
        NetworkListener.Remove<m_buff_change_hp_toc>(NetBuff.ResponeBuffHpChange);
        //复活
        NetworkListener.Remove<m_role_dead_toc>(NetRevive.ResponeRoleDead);
        NetworkListener.Remove<m_role_relive_toc>(NetRevive.ResponeRoleRevive);
        //战斗模式
        NetworkListener.Remove<m_change_pk_mode_toc>(NetFightInfo.ResponeChangeFightMode);

        //RemoveMissionListener();
        DropNetworkMgr.DropRemoveListener();

        //RemoveCopyListener();
        //RemoveWingListener();
        //RemoveFriendListener();
        RemoveFamilyListener();
        //RemoveTeamListener();
        //RemoveRankListener();
        NetWorldBoss.RemoveListener();
        OffLineBatMgr.RemoveSlOfflListener();
    }
    #endregion

    #region Client -> Server
    /// <summary>
    /// 请求进入游戏/连接并发送登录协议
    /// </summary>
    public static void ReqEnter()
    {
        NetworkClient.Connect("192.168.2.243", 55555, ConnectCallback, null, System.Net.Sockets.AddressFamily.InterNetwork);
    }

    public static void ReqEnterIp(string id, string name, string ip, int port)
    {
        User.instance.ServerID = string.IsNullOrEmpty(id) ? "0" : id;
        User.instance.ServerName = string.IsNullOrEmpty(name) ? "无" : name;
        User.instance.IP = ip;
        User.instance.Port = port;
        NetworkClient.Connect(ip, port, ConnectCallback, null, System.Net.Sockets.AddressFamily.InterNetwork);
    }

    private static bool CheckDNS(string dns)
    {
        for (int i = 0; i < dns.Length; i++)
        {
            char s = dns[i];
            if (char.IsLetter(s) || char.IsLower(s)) return true;
        }
        return false;
    }

    public static void ReqEnterDns(string id, string name, string dns, int port)
    {
        if (!CheckDNS(dns))
        {
            ReqEnterIp(id, name, dns, port);
            return;
        }
        User.instance.ServerID = string.IsNullOrEmpty(id) ? "0" : id;
        User.instance.ServerName = string.IsNullOrEmpty(name) ? "无" : name;
        User.instance.IP = dns;
        User.instance.Port = port;

        /*IPHostEntry hostInfo = Dns.GetHostEntry(dns);
        IPAddress ipAddress = hostInfo.AddressList[0];

        NetworkClient.Connect(ipAddress.ToString(), port, ConnectCallback, null, ipAddress.AddressFamily);*/

        Connect(dns, port, ConnectCallback);
    }


    public static void Connect(string host, int port, Action<string> cb)
    {
        data.host = host;
        data.port = port;
        data.cb = cb;

#if UNITY_EDITOR
        ConnectSync(host, port, cb);
#else

        while (!ThreadPool.QueueUserWorkItem(ConnectAsync, data))
        {
            Thread.Sleep(10);
        }
#endif
    }

    private static void ConnectAsync(object o)
    {
        try
        {
            IPHostEntry hostInfo = null;
            hostInfo = Dns.GetHostEntry(data.host);
            IPAddress ipAddress = hostInfo.AddressList[0];
            NetworkClient.Connect(ipAddress.ToString(), data.port, data.cb, null, ipAddress.AddressFamily);
        }
        catch (Exception e)
        {
            if (data.cb != null)
            {
                MonoEvent.AddOneShot(() => { data.cb(e.Message); });
            }
        }
    }

    private static void ConnectSync(string host, int port, Action<string> cb)
    {
        try
        {
            NetworkClient.Connect(host, port, cb, null, AddressFamily.InterNetwork);
        }
        catch (Exception e)
        {
            if (cb != null) cb(e.Message);
        }
    }



    /// <summary>
    /// 请求登陆
    /// </summary>
    public static void ReqLogin(string account, string md5, int serverid, string channelid, string gamechannelid)
    {
#if UNITY_EDITOR
        iTrace.eLog("hs", "请求登陆");
#endif
        int time = (int)(Utility.GetCurTime() * 0.001f);
        m_auth_key_tos req = ObjPool.Instance.Get<m_auth_key_tos>();
        req.account_name = account;
        req.key = Md5Crypto.Gen(md5 + time.ToString()).ToLower();
        req.time = time;
        req.server_id = serverid;
        req.pf_args.Add(channelid);
        req.pf_args.Add(gamechannelid);
        List<string> infos = ReConnectMgr.instance.GetCnnInfo();
        req.device_args.AddRange(infos);
        NetworkClient.Send<m_auth_key_tos>(req);
    }

    public static void ReqCreate(string name, int sex, int cate)
    {
#if UNITY_EDITOR
        iTrace.eLog("hs", "请求创建角色");
#endif
        m_create_role_tos req = ObjPool.Instance.Get<m_create_role_tos>();
        req.name = name;
        req.sex = sex;
        req.category = cate;
        NetworkClient.Send<m_create_role_tos>(req);
    }

    /// <summary>
    /// 选择角色
    /// </summary>
    /// <param name="roleId"></param>
    public static void ReqSelect(string sroleId, int lv)
    {
        Int64 roleId = Convert.ToInt64(sroleId);
        m_select_role_tos data = ObjPool.Instance.Get<m_select_role_tos>();
        data.role_id = roleId;
        selectRole = data;

        ReqSelect();
    }

    [NoToLua]
    public static void ReqSelect()
    {
        HeartBeat.instance.FSpDLing = false;
        NetworkClient.Send<m_select_role_tos>(selectRole);
    }

    /// <summary>
    /// 删除角色
    /// </summary>
    /// <param name="roleId"></param>
    public static void ReqDel(Int64 roleId)
    {
        m_del_role_tos data = ObjPool.Instance.Get<m_del_role_tos>();
        data.role_id = roleId;
        NetworkClient.Send<m_del_role_tos>(data);
    }

    /// <summary>
    /// 请求进入场景 Lua传入
    /// </summary>
    /// <param name="sceneid"></param>
    /// <param name="extraid"></param>
    /// <param name="load"></param>
    /// <param name="isCleck"></param>
    public static void ReqPreEnter(int sceneid, string extraid, bool isCleck = true)
    {
        ReqPreEnter(sceneid, Convert.ToInt64(extraid), isCleck);
    }

    /// <summary>
    /// 请求进入场景
    /// </summary>
    public static bool ReqPreEnter(int sceneid, long extraid = 0, bool isCleck = true)
    {
        Unit mainPlayer = InputVectorMove.instance.MoveUnit;
        if (mainPlayer != null && mainPlayer.mUnitMove.IsJumping == true)
        {
            UITip.LocalLog(690005);
            return false;
        }

        /**
        if(User.instance.SceneId == sceneid)
        {
            iTrace.eError("hs", "同一场景不能切换。。。");
            return;
        }
    */
#if UNITY_EDITOR
        if (!HadResource(sceneid))
#else
        if (!GameSceneManager.instance.CheckSceneRes((uint)sceneid))
#endif
        {
            ReqPreEnter(0, extraid, isCleck);
            return false;
        }
        if (isCleck && GameSceneManager.instance.CheckChangeScene((uint)sceneid))
        {
            UITip.LocalError(690006);
            return false;
        }
        if (IsLoadReady == true) return true;

        IsLoadReady = true;
        ModuleMgr.BegChgScene();
#if GAME_DEBUG
        iTrace.eLog("hs", string.Format("请求进入场景{0}效验", sceneid));
#endif
        User.instance.MapData.HasInitPos = false;
        m_pre_enter_tos req = ObjPool.Instance.Get<m_pre_enter_tos>();
        req.map_id = sceneid;
        req.extra_id = extraid;
        NetworkClient.Send<m_pre_enter_tos>(req);

        return true;
    }


    /// LY add begin ///

    /// <summary>
    /// 请求进入场景
    /// </summary>
    public static bool PortalPreChangeScene(int sceneid, int jumpId = 0, int desJumpId = 0, bool isCleck = true, long desPos = 0)
    {
#if UNITY_EDITOR
        if (!HadResource(User.instance.SceneId))
#else
        if (!GameSceneManager.instance.CheckSceneRes((uint)sceneid))
#endif
        {
            return false;
        }
        if (isCleck && GameSceneManager.instance.CheckChangeScene((uint)sceneid))
        {
            UITip.LocalError(690006);
            iTrace.eError("xioayu", "特殊场景不能切换副本");
            return false;
        }
        if (IsLoadReady == true) return true;

        IsLoadReady = true;
        ModuleMgr.BegChgScene();
#if GAME_DEBUG
        iTrace.eLog("hs", string.Format("请求进入场景{0}效验", sceneid));
#endif
        User.instance.MapData.HasInitPos = false;

        m_map_change_pos_tos changePos = ObjPool.Instance.Get<m_map_change_pos_tos>();
        changePos.dest_pos = desPos;
        changePos.map_id = sceneid;
        changePos.jump_id = jumpId;
        changePos.dest_jump_id = desJumpId;
        NetworkClient.Send<m_map_change_pos_tos>(changePos);
        return true;
    }

    /// LY add end ///


    /// <summary>
    /// 进入场景
    /// </summary>
    /// <param name="sceneid"> 场景id </param>
    public static void EnterScene(int sceneid)
    {
#if GAME_DEBUG
        iTrace.eLog("hs", "进入场景{0}", sceneid);
#endif
        try
        {
            DropMgr.CleanDropList();
        }
        catch (Exception e)
        {
            iTrace.Error("HY", "EnterScene err:{0}", e.Message);
        }
        m_enter_map_tos req = ObjPool.Instance.Get<m_enter_map_tos>();
        req.map_id = sceneid;
        NetworkClient.Send<m_enter_map_tos>(req);
    }

    /// <summary>
    /// 退出场景
    /// </summary>
    public static void QuitScene()
    {
#if UNITY_EDITOR
        iTrace.eLog("hs", "请求退出场景");
#endif
        HangupMgr.instance.ClearAutoInfo();
        User.instance.MissionState = false;
        User.instance.StopNavPath();
        m_quit_map_tos req = ObjPool.Instance.Get<m_quit_map_tos>();
        NetworkClient.Send<m_quit_map_tos>(req);
    }
    #endregion

    #region Server -> Client

    private static void RespRoleLogin(object obj)
    {
        EventMgr.Trigger(EventKey.RoleLogin);
    }
    private static void ConnectCallback(string error)
    {
        if (string.IsNullOrEmpty(error))
        {
            NetworkClient.DisableSend = false;
            EventMgr.Trigger("OnConnect");
        }
        else
        {
            MsgBox.SetConDisplay(true);
            var t1 = Lang.Instance.GetDes(620007);
            var t2 = Lang.Instance.GetDes(620008);
            var t3 = Lang.Instance.GetDes(690001);
            MsgBox.Show(t1, t2, ReConnectMgr.ReConnect, t3, ReConnectMgr.ExitApp);
            MsgBox.closeOpt = MsgBox.CloseOpt.No;
            iTrace.eError("hs", string.Format("连接服务器失败:{0}", error));
        }
    }

    /// <summary>
    /// 服务器错误响应
    /// </summary>
    private static void RespSystemErroer(object obj)
    {
        if (AntiIndex == 1)
        {
            HeartBeat.instance.IsStop = true;
            AntiIndex = 0;
            return;
        }
        m_system_error_toc resp = obj as m_system_error_toc;
        if (resp.need_reconnect == true)
            HeartBeat.SetRcnn();
        else
        {
            NetworkClient.Disconnect();
            HeartBeat.instance.Reset();
            string err = ErrorCodeMgr.GetError(resp.error_code);
            MsgBox.Show(err, null, ReConnectMgr.ReLogin);
            MsgBox.closeOpt = MsgBox.CloseOpt.Yes;
        }
    }

    /// <summary>
    /// 登陆返回
    /// </summary>
    private static void RespLogin(object obj)
    {
        m_auth_key_toc resp = obj as m_auth_key_toc;
        EventMgr.Trigger("IsOpenGM", resp.is_gm);
        if (resp.err_code == 0)
        {
            Debug.Log("登陆成功");
            List<p_login_role> list = resp.role_list;
            for (int i = 0; i < list.Count; i++)
            {
                p_login_role role = list[i];
                EventMgr.Trigger("LoginRole", role.role_id, role.role_name, role.level, role.sex, role.category, role.skin_list);
            }
            EventMgr.Trigger("LoginSuc");
            HeartBeat.instance.LoginGame = true;
        }
        else
        {
            Debug.LogError("登入游戏失败");
            NetworkClient.Disconnect();
            EventMgr.Trigger("LoginFail");
            UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
        }
    }

    /// <summary>
    /// 创建角色返回
    /// </summary>
    /// <param name="obj"></param>
    private static void RespCreate(object obj)
    {
        m_create_role_toc resp = obj as m_create_role_toc;
        p_login_role role = resp.role;
        if (resp.err_code == 0)
        {
            EventMgr.Trigger("CreateSuc", role.role_id, role.role_name, role.level, role.sex, role.category, role.skin_list);
#if UNITY_EDITOR
            iTrace.eLog("hs", "创建角色成功");
#endif
        }
        else
        {
            UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
        }
    }

    /// <summary>
    /// 选择角色返回
    /// </summary>
    /// <param name="obj"></param>
    private static void RespSelect(object obj)
    {
        var roleInfo = obj as m_select_role_toc;
        var err = roleInfo.err_code;
        if (err == 0)
        {
            Int32 mapid = roleInfo.map_id;
            p_role_data data = roleInfo.role_data;
            User.instance.MapData.UpdateRoleData(data);
            // User.instance.IsCreateScene = isCreate;
            HeartBeat.instance.LoginGame = true;
            HeartBeat.ReqHeartbeat();
            // EventMgr.Trigger(EventKey.CamOpen);
            bool isLoad = User.instance.SceneId != roleInfo.map_id;
            if (!isLoad) Loong.Game.DisposeTool.SameScene();
            User.instance.SceneId = roleInfo.map_id;
            //User.instance.LimitExp = data.attr.next_level_exp;
            NetAttr.RoleBaseUpdate(data.@base);
            //PetMessage.instance.Init();         

            int sceneId = User.instance.SceneId;
#if UNITY_EDITOR
            if (!HadResource(User.instance.SceneId))
#else
            if (App.IsSubAssets == true && !GameSceneManager.instance.CheckSceneRes((uint)User.instance.SceneId))
#endif
            {
                sceneId = 0;
            }
            ReqPreEnter(sceneId, 0, false);
            //if (!Application.isEditor) ChatVoiceMgr.Login(roleInfo.role_data.attr.role_name,roleInfo.role_data.role_id);

            EventMgr.Trigger("SelectSuc");
        }
        else
        {
            UITip.Error(ErrorCodeMgr.GetError(err));
        }
    }


    /// <summary>
    /// 删除角色返回
    /// </summary>
    /// <param name="obj"></param>
    private static void RespDel(object obj)
    {
        m_del_role_toc resp = obj as m_del_role_toc;
        if (resp.err_code == 0)
        {
            UITip.LocalLog(690009);
        }
        else
            UITip.Error(ErrorCodeMgr.GetError(resp.err_code));
    }
    /// <summary>
    /// 请求进入地图返回
    /// </summary>
    /// <param name="obj"></param>
    private static void RespPreEnter(object obj)
    {

        m_pre_enter_toc resp = obj as m_pre_enter_toc;
        IsHadResource = true;
        if (resp.err_code == 0)
        {
            PickIcon.DestroyPickIcon();
            CameraMgr.ClearPullCam();
            int sceneID = resp.map_id;
            if (ReqPreID == sceneID)
            {
                iTrace.eError("hs", string.Format("重复请求进入{0}场景", sceneID));
                return;
            }
            ReqPreID = sceneID;
            GameSceneManager.instance.ChangeScene(sceneID);
            MapPathMgr.instance.SetWantDesPos(resp.pos);
        }
        else
        {
            ReqPreID = 0;
            IsLoadReady = false;
            User.instance.MapData.HasInitPos = true;
            iTrace.Log("Loong", ErrorCodeMgr.GetError(resp.err_code));
            EventMgr.Trigger("ChangeSceneFail");
            //MsgBox.Show(ErrorCodeMgr.GetError(resp.err_code), "确定", null);
            UITip.Log(ErrorCodeMgr.GetError(resp.err_code));
        }
    }

    /// <summary>
    /// 进入地图返回
    /// </summary>
    private static void RespEnterScene(object obj)
    {
        ReqPreID = 0;
        m_enter_map_toc resp = obj as m_enter_map_toc;
        IsLoadReady = false;
        User.instance.IsMissionFlowChart = false;
        if (resp.err_code == 0)
        {
            int sceneID = resp.map_id;
            long extraID = resp.extra_id;
            User.instance.SceneId = sceneID;
            User.instance.ExtraId = extraID;
            if (User.instance.SceneId == 0) User.instance.SceneId = 10001;    //临时处理
#if GAME_DEBUG
            iTrace.eLog("hs", string.Format("进入场景{0}地图", User.instance.SceneId));
#endif
            p_map_actor mapData = resp.role_map_info;
            User.instance.MapData.UpdateActor(mapData);
            // GameSceneManager.instance.First = false;
            if (User.instance.IsInitLoadScene) User.instance.IsInitLoadScene = false;
            ModuleMgr.EndChgScene();

            EventMgr.Trigger(EventKey.OnChangeScene, sceneID);
            HeartBeat.instance.IsStop = false;
            //GameSceneManager.instance.LoadScene(User.instance.SceneId);
        }
        else
        {
            iTrace.Log("Loong", ErrorCodeMgr.GetError(resp.err_code));
        }
    }

    /// <summary>
    /// 退出副本返回
    /// </summary>
    private static void RespQuitScene(object obj)
    {
        m_quit_map_toc resp = obj as m_quit_map_toc;
        if (resp.err_code == 0)
        {
            int mapid = resp.map_id;
            if (mapid <= 0)
            {
                iTrace.eError("hs", string.Format("退出地图返回的副本id错误 error mapid：{0}", mapid));
                return;
            }
            SceneInfo info = SceneInfoManager.instance.Find((uint)mapid);
            if (info != null)
            {
                HangupMgr.instance.IsAutoHangup = false;
                HangupMgr.instance.IsAutoSkill = false;
            }

            GameSceneManager.instance.ChangeScene(mapid);
        }
        else
        {
            iTrace.eError("Loong", ErrorCodeMgr.GetError(resp.err_code));
        }
    }

    /// <summary>
    /// 地图区域改变
    /// </summary>
    private static void RespMapSliceEnter(object obj)
    {
        //UITip.EditorLogWarning("响应地图区域改变");
        m_map_slice_enter_toc resp = obj as m_map_slice_enter_toc;
        User.instance.UpdateSliceMapActor(resp.actors);
        List<long> delActors = resp.del_actors;
        User.instance.DeleteSliceMapActor(delActors);
    }

    /**
    /// <summary>
    /// 功能开启
    /// </summary>
    /// <param name="obj"></param>
    private static void RespFunctionList(object obj)
    {
        m_function_list_toc resp = obj as m_function_list_toc;
        List<int> list = resp.id_list;
        for (int i = 0; i < list.Count; i++)
        {
            int key = list[i];
            EventMgr.Trigger(EventKey.OpenSystem, key, resp.op_type);
            
            if (!User.instance.SystemOpenList.Contains(key))
            {
                //HangupMgr.instance.OpenSysStopHg((ushort)key);
                User.instance.SystemOpenList.Add(key);
            }
        }
        if (User.instance.IsInitLoadScene) return;
        EventMgr.Trigger(EventKey.OpenSystemEnd, resp.op_type);
        //if ((OperationType)resp.op_type == OperationType.Update) OperationMgr.instance.OpenSystemUI();
    }
    */
    #endregion

    #region 其他功能
    /// <summary>
    /// 防沉迷
    /// </summary>
    private static void AntiIndulge(params object[] args)
    {
        if (args == null)
            return;
        if (args.Length == 0)
            return;
        AntiIndex = Convert.ToInt32(args[0]);
    }

    public static void DisConnect()
    {
        NetworkClient.Disconnect();
    }

    /// <summary>
    /// 检测是否拥有场景资源
    /// </summary>
    /// <param name="sceneId"></param>
    public static bool HadResource(int sceneId)
    {
        if (sceneId == 0)//场景id为0，默认服务端控制场景切换
        {
            return true;
        }
        SceneInfo info = SceneInfoManager.instance.Find((uint)sceneId);
        if(info == null)
        {
            return false;
        }

        List<Table.String> list = info.resName.list;
        foreach (var resName in list)
        {
            if (string.IsNullOrEmpty(resName))
            {
                return false;
            }

            string path = resName.ToString().ToLower() + Suffix.Scene;//+ Suffix.AB;
            if (!AssetMgr.Instance.Exist(path))
            {
                return false;
            }
            string nextMapData = string.Concat(info.mapId.ToString(), ".bytes");
            string nextMapBlock = string.Concat(info.mapId.ToString(), "_block.prefab");
            if (AssetMgr.Instance.Exist(nextMapData) == false
                || AssetMgr.Instance.Exist(nextMapBlock) == false)
            {
                return false;
            }
        }
        return true;
    }
    #endregion
}
