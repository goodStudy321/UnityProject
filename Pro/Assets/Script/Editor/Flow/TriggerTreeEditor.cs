using System;
using Phantom;
using Loong.Game;
using Loong.Edit;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;
using Object = UnityEngine.Object;
public class TriggerTreeEditor : EditWinBase
{

    #region 字段
    public static TriggerTreeEditor Instance = null;
    #endregion

    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    private void Register()
    {

        EditorSceneManager.activeSceneChanged += ActiveSceneChanged;
#pragma warning disable 618
        EditorApplication.playmodeStateChanged += PlaymodeStateChanged;
#pragma warning restore
    }

    private void PlaymodeStateChanged()
    {
        TriggerEditView editView = Get<TriggerEditView>();
        if (EditorApplication.isPlaying)
        {
            if (!editView.Active) Switch<TriggerEditView>();
            editView.DebugMode = true;
        }
        else
        {
            Switch<TriggerSceneView>();
            editView.DebugMode = false;
        }
        Repaint();
    }

    private void ActiveSceneChanged(Scene s0, Scene s1)
    {
        if (!EditorApplication.isPlaying)
        {
            Close();
        }
    }

    private static bool CheckTip()
    {
        if (EditorApplication.isPlaying) return true;
        var tip = "1. 若节点属性字段需要新增/删除/修改,先将本地配置提交,等程序自动生成后再更新编辑;\n2. 记得编辑完要随手保存;\n3. 编辑的同时进行脚本刷新,会造成数据丢失.";
        return EditorUtility.DisplayDialog("", tip, "确定", "退出");
    }

    #endregion

    #region 保护方法

    protected override void OnDestroy()
    {
        EditorSceneManager.activeSceneChanged -= ActiveSceneChanged;
#pragma warning disable 618
        EditorApplication.playmodeStateChanged -= PlaymodeStateChanged;
#pragma warning restore
        Instance = null;
        base.OnDestroy();
    }

    protected override void OnCompiled()
    {
        Register();
    }
    #endregion

    #region 公开方法

    [MenuItem(MenuTool.Plan + "流程树编辑器 %T", false, -1001)]
    [MenuItem(MenuTool.APlan + "流程树编辑器", false, -1001)]

    public static void Open()
    {
        if (CheckTip())
        {
            WinUtil.Open<TriggerTreeEditor>();
        }
    }

    public override void Init()
    {
        Instance = this;
        Add<TriggerSceneView>();
        Add<TriggerEditView>();
        PlaymodeStateChanged();
        Register();
    }
    #endregion


}