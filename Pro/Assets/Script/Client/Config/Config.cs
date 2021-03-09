using System;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using Lang = Phantom.Localization;

/// <summary>
/// AU:Loong
/// TM:2017.05.15
/// CO:ShenLong.SLRPGA
/// BG:配置
/// </summary>
public static class Config
{
    #region 字段

    /// <summary>
    /// 加载完成回调
    /// </summary>
    private static Action callback = null;

    /// <summary>
    /// 表格实例列表
    /// </summary>
    public static List<object> tables = new List<object>();

    #endregion

    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    /// <summary>
    /// 设置表格实例列表
    /// </summary>
    private static void SetTables()
    {
        List<Type> tableTypes = ReflectionTool.GetGenericSubType(typeof(Table.Manager<>));
        if (tableTypes == null) return;
        int length = tableTypes.Count;
        for (int i = 0; i < length; i++)
        {
            Type tableType = tableTypes[i];
            BindingFlags flags = BindingFlags.Static | BindingFlags.Public;
            PropertyInfo propInfo = tableType.GetProperty("instance", flags);
            if (propInfo == null) continue;
            object obj = propInfo.GetValue(null, null);
            tables.Add(obj);
        }
    }

    /// <summary>
    /// 预加载表格资源
    /// </summary>
    private static void PreLoadTable()
    {
        if (tables == null || tables.Count == 0) return;
        List<string> tableNames = new List<string>();
        string folder = "table";

        int length = tables.Count;
        for (int i = 0; i < length; i++)
        {
            object obj = tables[i];
            Type type = obj.GetType();
            BindingFlags flags = BindingFlags.Public | BindingFlags.Instance;
            PropertyInfo propInfo = type.GetProperty("source", flags);

            object srcObj = propInfo.GetValue(obj, null);
            string srcVal = srcObj.ToString();
            tableNames.Add(srcVal);
        }
        FileLoader.instance.Ipro = UILoading.Instance;
        FileLoader.instance.LoadTableFile(tableNames, folder, true, Set);
    }

    /// <summary>
    /// 加载表格
    /// </summary>
    /// <returns></returns>
    private static bool LoadTable()
    {
        if (tables == null) return false;
        string folder = "table";
        int length = tables.Count;
        for (int i = 0; i < length; i++)
        {
            object obj = tables[i];
            Type type = obj.GetType();
            Type[] argTypes = new Type[] { typeof(string) };
            MethodInfo loadMethodInfo = type.GetMethod("Load", argTypes);
            object[] args = new object[] { folder };
            loadMethodInfo.Invoke(obj, args);
        }

        return true;
    }

    /// <summary>
    /// 设置配置
    /// </summary>
    private static void Set()
    {
        Global.Main.StartCoroutine(YieldSet());
    }

    private static void SetMsg(uint id)
    {
        var msg = Lang.Instance.GetDes(id);
        UILoading.Instance.SetMessage(msg);
    }

    private static IEnumerator YieldSet()
    {
        yield return 0;
        SetMsg(617039);
        LocalCfgManager.instance.Clear();
        LoadTable();
        BuglyMgr.Restart();
        iTrace.Log("Loong", "load table complete");
        SetMsg(617040);
        yield return 0;
        LoadActionSetup();
#if GAME_DEBUG
        iTrace.Log("Loong", "Load ActionSetup end");
#endif
        yield return 0;
        SetMsg(617045);
        LuaTool.Call("Main", "Init");
        App.Refresh();
        Global.Initialize();
        ProtoMgr.Load();
        ErrorCodeMgr.Load();
        NetworkMgr.AddListener();
        /// LY add begin ///
        MapPathMgr.instance.LoadSimplifyMap();
        PathTool.PathMoveMgr.instance.LoadData();
        AppearCtrlZoneMgr.instance.Initialize();
        /// LY add end ///

        AssetMgr.Instance.complete += Complete;
        AssetMgr.Start();
    }


    /// <summary>
    /// 加载初始资源结束
    /// </summary>
    private static void Complete()
    {
        AssetMgr.Instance.complete -= Complete;
        if (callback != null)
        {
            callback();
            callback = null;
        }
    }

    /// <summary>
    /// 刷新动作编辑数据
    /// </summary>
    private static void LoadActionSetup()
    {
        Global.ActionSetupData = ActionHelper.GetActionSetupDataFromFile();
        //var data = ActionHelper.GetGroupData(1001, 0);
        UnitMgr.instance.RefreshUnitActionSetup();
    }

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法

    /// <summary>
    /// 加载配置
    /// </summary>
    /// <param name="cb">加载完成回调</param>
    public static void Load(Action cb)
    {
        callback = cb;
        IProgress iPro = UILoading.Instance;
        if (iPro != null)
        {
            iPro.Open();
            var msg = Lang.Instance.GetDes(617046);
            iPro.SetMessage(msg);
        }
        SetTables();
        PreLoadTable();
    }


#if UNITY_EDITOR
    /// <summary>
    /// 在editor中读表
    /// </summary>
    public static void LoabTableInEditor()
    {
        SetTables();
        LoadTable();
    }
#endif

    #endregion
}