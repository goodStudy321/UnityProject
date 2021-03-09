using System;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using HandleDic = System.Collections.Generic.Dictionary<string, System.Action<string>>;

using Slate;

/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        fd786c4e-be3b-4e57-ac10-9ecc9a683888
*/

/// <summary>
/// AU:Loong
/// TM:2017/5/11 15:59:12
/// BG:LuaUI管理器
/// </summary>
public static class UIMgr
{
    #region 字段
    private static Camera cam = null;

    private static Camera hCam = null;

    private static Camera stCam = null;

    private static Transform root = null;

    private static LuaTable luaTable = null;

    private static LuaFunction openFunc = null;

    private static LuaFunction closeFunc = null;

    private static LuaFunction closeAllFunc = null;

    private static LuaFunction addFunc = null;

    private static LuaFunction getFunc = null;

    private static LuaFunction removeFunc = null;

    private static LuaFunction disposeFunc = null;

    private static LuaFunction recordOpens = null;

    private static LuaFunction openRecords = null;

    private static LuaFunction reOpens = null;
    /// <summary>
    /// 回调字典
    /// </summary>
    private static HandleDic handleDic = new HandleDic();

    //// LY add begin ////

    private static Camera sceneRtCam = null;

    /// <summary>
    /// 场景渲染面板物体
    /// </summary>
    private static GameObject rtPanelObj = null;

    //// LY add end ////

    #endregion

    #region 属性
    /// <summary>
    /// UI相机
    /// </summary>
    public static Camera Cam
    {
        get { return cam; }
        set { cam = value; }
    }

    /// <summary>
    /// 深度更高层级相机
    /// </summary>
    public static Camera HCam
    {
        get { return hCam; }
        set { hCam = value; }
    }

    public static Camera STCam
    {
        get { return stCam; }
        set { stCam = value; }
    }


    /// <summary>
    /// 根结点
    /// </summary>
    public static Transform Root
    {
        get { return root; }
        set { root = value; }
    }

    /// <summary>
    /// 开关效果总开关
    /// </summary>
    public static bool UseOnOffEffect
    {
        get
        {
            if (luaTable == null) return false;
            return (bool)luaTable["UseOnOffEffect"];
        }
        set
        {
            if (luaTable == null) return;
            luaTable["UseOnOffEffect"] = value;
        }
    }

    //// LY add begin ////
    
    public static Camera SceneRtCam
    {
        get { return sceneRtCam; }
        set { sceneRtCam = value; }
    }
    
    public static GameObject RtPanelObj
    {
        get { return rtPanelObj; }
        set { rtPanelObj = value; }
    }

    //// LY add end ////

    #endregion

    #region 构造方法
    static UIMgr()
    {
        Init();
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 初始化
    /// </summary>
    private static void Init()
    {
        if (!Application.isPlaying) return;
        Root = UITool.CreateRoot(1334, 750, 8);
        Cam = ComTool.Get<Camera>(Root, "Camera", "UIMgr get cam");
        Cam.useOcclusionCulling = false;
        cam.allowHDR = false;
        cam.allowMSAA = false;
        AddHCam();
        AddSTCam();
        GameObject.DontDestroyOnLoad(Root);
        EventMgr.Add(EventKey.UIOpen, ExeHandle);

        //// LY add begin ////

        //SceneRtCam = Root.Find("RTCamera").GetComponent<Camera>();
        //RtPanelObj = Root.Find("RTCamera/RTPanel").gameObject;
        //CameraMgr.CheckAndGetShowRT();

        EventMgr.Add(EventKey.GetLocalString, GetLocalString);

        //// LY add end ////
    }

    private static void AddHCam()
    {
        GameObject go = GameObject.Instantiate(cam.gameObject);
        go.name = "HCam";

        Transform tran = go.transform;
        tran.parent = Root;
        tran.localScale = Vector3.one;
        tran.localPosition = new Vector3(0, 0, -8000 * 10);
        hCam = go.GetComponent<Camera>();
        hCam.depth = 100;
    }

    private static void AddSTCam()
    {
        GameObject go = GameObject.Instantiate(cam.gameObject);
        go.name = "STCam";

        Transform tran = go.transform;
        tran.parent = Root;
        tran.localScale = Vector3.one;
        tran.localPosition = new Vector3(0, 0, -9000 * 10);
        stCam = go.GetComponent<Camera>();
        stCam.depth = 100;
        stCam.gameObject.SetActive(false);
    }

    /// <summary>
    /// 处理回调
    /// </summary>
    /// <param name="args"></param>
    private static void ExeHandle(params object[] args)
    {
        if (args == null || args.Length < 1) return;
        string uiname = args[0].ToString();
        if (!handleDic.ContainsKey(uiname)) return;
        Action<string> cb = handleDic[uiname];
        if (cb == null) return;
        handleDic.Remove(uiname);
        cb(uiname);
    }

    /// <summary>
    /// 添加回调
    /// </summary>
    /// <param name="name"></param>
    /// <param name="cb"></param>
    private static void AddHandle(string name, Action<string> cb)
    {
        if (handleDic.ContainsKey(name))
        {
            handleDic[name] += cb;
        }
        else
        {
            handleDic.Add(name, cb);
        }
    }
    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    /// <summary>
    /// 设置Lua方法
    /// </summary>
    public static void Refresh()
    {
        string tableName = "UIMgr";
        luaTable = LuaTool.GetTable(LuaMgr.Lua, tableName);
        addFunc = LuaTool.GetFunc(luaTable, "Add");
        getFunc = LuaTool.GetFunc(luaTable, "Get");
        openFunc = LuaTool.GetFunc(luaTable, "Open");
        closeFunc = LuaTool.GetFunc(luaTable, "Close");
        closeAllFunc = LuaTool.GetFunc(luaTable, "CloseAll");
        removeFunc = LuaTool.GetFunc(luaTable, "Remove");
        disposeFunc = LuaTool.GetFunc(luaTable, "Dispose");
        recordOpens = LuaTool.GetFunc(luaTable, "RecordOpens");
        openRecords = LuaTool.GetFunc(luaTable, "OpenRecords");
        reOpens = LuaTool.GetFunc(luaTable, "ReOpens");
        luaTable["Root"] = Root;
        luaTable["Cam"] = Cam;
        luaTable["HCam"] = hCam;
        luaTable["STCam"] = stCam;
    }

    /// <summary>
    /// 打开面板
    /// </summary>
    /// <param name="name">面板名称</param>
    /// <param name="cb">回调</param>
    public static void Open(string name, Action<string> cb = null)
    {
        if (string.IsNullOrEmpty(name)) return;
        if (cb != null) AddHandle(name, cb);
        LuaTool.Call(openFunc, name);

    }

    /// <summary>
    /// 关闭面板
    /// </summary>
    /// <param name="name">面板名称</param>
    public static void Close(string name)
    {
        if (string.IsNullOrEmpty(name)) return;
        LuaTool.Call(closeFunc, name);
    }

    /// <summary>
    /// 关闭所有面板
    /// </summary>
    public static void CloseAll()
    {
        LuaTool.Call(closeAllFunc);
    }

    /// <summary>
    /// 获取UI面板(LuaTable)
    /// </summary>
    /// <param name="name">面板名称</param>
    /// <returns></returns>
    public static LuaTable Get(string name)
    {
        if (string.IsNullOrEmpty(name)) return null;
        if (getFunc == null)
        {
            iTrace.Error("Loong", "对应的Lua Get方法为空");
            return null;
        }
        getFunc.BeginPCall();
        getFunc.Push(name);
        getFunc.PCall();
        LuaTable luaTable = getFunc.CheckLuaTable();
        getFunc.EndPCall();
        return luaTable;
    }

    /// <summary>
    /// 添加面板
    /// </summary>
    /// <param name="go">游戏对象</param>
    public static void Add(GameObject go)
    {
        if (go == null) return;
        LuaTool.Call(addFunc, go);
    }

    /// <summary>
    /// 移除面板
    /// </summary>
    /// <param name="name">面板名称</param>
    public static void Remove(string name)
    {
        if (string.IsNullOrEmpty(name)) return;
        LuaTool.Call(removeFunc, name);
    }

    /// <summary>
    /// 记录已经打开的面板并关闭
    /// </summary>
    /// <param name="selfName">无需记录的面板</param>
    public static void RecordOpens(string selfName)
    {
        if (selfName == null) selfName = "";
        LuaTool.Call(recordOpens, selfName);
    }

    /// <summary>
    /// 打开已经关闭的面板
    /// </summary>
    public static void OpenRecords()
    {
        LuaTool.Call(openRecords);
    }

    /// <summary>
    /// 重新打开固定的面板
    /// </summary>
    public static void ReOpens()
    {
        LuaTool.Call(reOpens);
    }

    /// <summary>
    /// 释放
    /// </summary>
    public static void Dispose()
    {
        LuaTool.Call(disposeFunc);
    }

    public static void SetCamActive(bool at, float mainDepth = -1)
    {
        CameraMgr.SetMainDepth(mainDepth);
        if (Cam != null)
        {
            Cam.enabled = at;
        }
        if (HCam != null)
        {
            HCam.enabled = at;
        }
        //if(STCam != null && at == false)
        //{
        //    STCam.enabled = at;
        //}
    }

    public static void CreateRTCom()
    {
        if (Root == null)
            return;

        UITool.CreateRTCom(Root);
        
        SceneRtCam = Root.Find("RTCamera").GetComponent<Camera>();
        RtPanelObj = Root.Find("RTCamera/RTPanel").gameObject;
        CameraMgr.CheckAndGetShowRT();
    }

    //// LY add begin ////
    
    public static void GetLocalString(params object[] args)
    {
        if(args.Length < 2)
        {
            return;
        }

        int index = (int)args[0];
        if (index < 0)
        {
            iTrace.eError("LY", "Index error !! " + index);
            return;
        }
        string showStr = Phantom.Localization.Instance.GetDes(index);

        if(args[1] is DirectorGUI)
        {
            DirectorGUI.SetTipText(showStr);
        }
        
    }
    
    //// LY add end ////

    #endregion
}