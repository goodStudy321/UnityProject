using System;
using Phantom;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

/*
 * CO:            
 * Copyright:   2016-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        bcb91820-c6ad-4a38-bbf4-e8a06fb4a526
*/

/// <summary>
/// AU:Loong
/// TM:2016/10/18 12:18:28
/// BG:流程树管理类
/// </summary>
public static class FlowChartMgr
{
    #region 字段

    private static Transform root = null;

    private static FlowChart current = null;

    private static List<FlowChart> flows = new List<FlowChart>();

    /// <summary>
    /// 流程树字典
    /// </summary>
    private static Dictionary<string, FlowChart> flowDic = new Dictionary<string, FlowChart>();

    #endregion

    #region 属性
    /// <summary>
    /// 流程树列表
    /// </summary>
    public static List<FlowChart> Flows
    {
        get { return flows; }
    }

    /// <summary>
    /// 当前流程树名称
    /// </summary>
    public static string CurName
    {
        get
        {
            return (current == null) ? null : current.name;
        }
    }

    /// <summary>
    /// 当前被启动的流程树
    /// </summary>
    public static FlowChart Current
    {
        get { return current; }
        set { current = value; }
    }


    /// <summary>
    /// 根节点
    /// </summary>
    public static Transform Root
    {
        get
        {
            if (root == null)
            {
                root = TransTool.CreateRoot<FlowChart>();
            }
            return root;
        }
    }
    #endregion

    #region 委托事件

    #endregion

    #region 构造方法
    static FlowChartMgr()
    {

    }
    #endregion

    #region 私有方法

    private static void Start(FlowChart flow)
    {
        if (flow == null) return;
        flow.Root.parent = Root;
        flow.Root.gameObject.SetActive(true);
        flow.StartUp();
    }


    /// <summary>
    /// 加载完成后启动流程树
    /// </summary>
    private static void LoadedStart(Object o)
    {
        var tt = AddFromObject(o);
        Start(tt);
    }

    private static FlowChart AddFromObject(Object o)
    {
        if (o == null)
        {
            iTrace.Error("Loong", "add is null"); return null;
        }
        if (flowDic.ContainsKey(o.name))
        {
            return flowDic[o.name];
        }
        var tt = new FlowChart();
        var text = (TextAsset)o;

        tt.Read(text);
        Add(tt);
        return tt;
    }

    private static void EnterPreload()
    {
        AssetMgr.Instance.complete -= EnterPreload;
        Preload();
        PreloadMgr.Execute();
        AssetMgr.Instance.Start();
    }
    #endregion

    #region 保护方法
    /// <summary>
    /// 移除事件
    /// </summary>
    public static event Action<string> remove = null;
    #endregion

    #region 公开方法
    /// <summary>
    /// 添加
    /// </summary>
    /// <param name="obj"></param>
    public static void Add(Object obj)
    {
        AddFromObject(obj);
    }

    /// <summary>
    /// 添加
    /// </summary>
    /// <param name="value">值</param>
    [NoToLua]
    public static void Add(FlowChart value)
    {
        if (value == null)
        {
            iTrace.Error("Loong", "add is null");
            return;
        }
        string key = value.name;
        if (flowDic.ContainsKey(key))
        {
            iTrace.Error("Loong", "{0} repeat add", key);
        }
        else
        {
            var ftTran = value.Root;
            ftTran.parent = Root;
            ftTran.gameObject.SetActive(true);
            flowDic.Add(key, value);
            flows.Add(value);
            value.Initialize();
        }
    }

    /// <summary>
    /// 移除
    /// </summary>
    /// <param name="key">键</param>
    public static void Remove(string key)
    {
        if (!flowDic.ContainsKey(key)) return;
        if (current != null && current.name.Equals(key)) Current = null; 
        var fc = flowDic[key];
        fc.Dispose();
        flows.Remove(fc);
        flowDic.Remove(key);
        if (remove != null) remove(key);
    }

    /// <summary>
    /// 移除
    /// </summary>
    /// <param name="value">值</param>
    [NoToLua]
    public static void Remove(FlowChart value)
    {
        if (value != null) Remove(value.name);
    }

    /// <summary>
    /// 获取流程树
    /// </summary>
    /// <param name="key"></param>
    /// <returns></returns>
    public static FlowChart Get(string key)
    {
        if (flowDic.ContainsKey(key)) return flowDic[key];
        return null;
    }

    /// <summary>
    /// 开始流程树
    /// </summary>
    /// <param name="key">流程树名称</param>
    public static void Start(string name)
    {
        if (string.IsNullOrEmpty(name)) return;
        if (flowDic.ContainsKey(name))
        {
            if (flowDic[name].Running)
            {
#if UNITY_EDITOR
                UITip.eError(string.Format("flowtree:{0},running,not repeat running", name));
#endif
            }
            else
            {
                Start(flowDic[name]);
            }
        }
        else
        {
            AssetMgr.Instance.Load(name, Suffix.Bytes, LoadedStart);
        }
    }

    /// <summary>
    /// 预加载
    /// </summary>
    [NoToLua]
    public static void Preload()
    {
        int length = flows.Count;
        for (int i = 0; i < length; i++)
        {
            flows[i].Preload();
        }
    }


    /// <summary>
    /// 预加载任务
    /// </summary>
    /// <param name="info"></param>
    [NoToLua]
    public static void PreloadMission(SceneInfo info)
    {
        Preload(info.missionTrigger);
        Preload(info.enterSceneTrigger);
    }


    [NoToLua]
    public static void PreloadAfterEnterScene(SceneInfo info)
    {
        Preload(info.enterSceneTrigger.list);
    }

    public static void Preload(SceneInfo.triggers triggers)
    {
        int length = triggers.list.Count;
        for (int i = 0; i < length; i++)
        {
            string name = triggers.list[i].ToString();
            AssetMgr.Instance.Add(name, Suffix.Bytes, FlowChartMgr.Add);
        }
    }

    /// <summary>
    /// 通过名称列表进行预加载
    /// </summary>
    /// <param name="lst"></param>
    public static void Preload(List<Table.String> lst)
    {
        if (lst == null) return;
        int length = lst.Count;
        for (int i = 0; i < length; i++)
        {
            var name = lst[i].ToString();
            if (flowDic.ContainsKey(name))
            {
                flowDic[name].Preload();
            }
        }
    }

    public static void Update()
    {
        for (int i = flows.Count - 1; i > -1; --i)
        {
            var flow = flows[i];
            flow.Update();
        }
    }

    /// <summary>
    /// 释放
    /// </summary>
    [NoToLua]
    public static void Dispose()
    {
        int length = flows.Count;
        for (int i = 0; i < length; i++)
        {
            flows[i].Dispose();
        }
        flows.Clear();
        flowDic.Clear();
        EndGame.CleanEndEvent();
        Current = null;
    }

    #endregion
}