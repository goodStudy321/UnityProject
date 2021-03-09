using System;
using Phantom;
using System.IO;
using Loong.Game;
using Loong.Edit;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;


/*
 *Loong 2015.11.9 大规模整理
 */

public class TriggerEditView : EditViewBase
{

    #region 字段
    private FlowChart tree;


    private Vector2 toolBtnScroll;

    private Vector2 propertyScroll;

    private float propertyScrollMaxY;

    private int nodeAreaWidth = 300;

    private Rect nodeArea = new Rect(300, 0, 2000, 2000);

    private GUILayoutOption[] tarOpt = new GUILayoutOption[] { GUILayout.Width(100) };

    private GUILayoutOption[] options = new GUILayoutOption[] { GUILayout.Height(25), GUILayout.Width(280) };

    #endregion


    #region 属性
    public bool DebugMode { get; set; }

    public FlowChart Tree
    {
        get
        {
            return tree;
        }
        set
        {
            tree = value;
            if (tree == null) return;
            tree.EditSetWindow(Win);
            if (DebugMode) return;
            tree.EditInitialize(this);
        }
    }
    #endregion


    #region 私有方法

    private void PingTree()
    {
        if (tree == null) return;
        if (tree.Root != null)
        {
            EditorGUIUtility.PingObject(tree.Root);
        }
    }

    private void CopyNode()
    {
        tree.EditCopyNode(this);
    }

    private void SetStartNode()
    {
        tree.EditSetStartNode(this);
    }

    private void Return()
    {
        if (DebugMode) return;
        if (!EditorUtility.DisplayDialog("", "资源保存了吗？\n\n确定返回吗？", "确定", "取消")) return;
        Win.Switch<TriggerSceneView>();
        if (Tree == null) return;
        Loong.Game.iTool.Destroy(Tree.Root.gameObject);
    }


    private void DrawDebugColor()
    {
        if (!NGUIEditorTools.DrawHeader("Debug模式颜色提示", "DebugMode")) return;
        EditorGUILayout.Space();
        GUILayout.Box("等待状态", "flow node 3", options);
        GUILayout.Box("准备状态", "flow node 1", options);
        GUILayout.Box("运行状态", "flow node 4", options);
        GUILayout.Box("结束状态", "flow node 0", options);
        GUILayout.Box("停止状态", "flow node 6", options);
    }

    private void DrawFlowCharts()
    {
        if (!NGUIEditorTools.DrawHeader("流程树列表", "Flows")) return;
        EditorGUILayout.Space();
        int length = FlowChartMgr.Flows.Count;
        if (length == 0) { EditorGUILayout.HelpBox("无", MessageType.Info); return; }
        string tip = null;
        for (int i = 0; i < length; i++)
        {
            FlowChart flow = FlowChartMgr.Flows[i];
            tip = flow.name;
            if (flow.Running) tip += ":运行中";
            if (Object.ReferenceEquals(flow, tree))
            {
                GUILayout.Box(tip, "flow node 0 on", options);
            }
            else
            {
                GUILayout.Box(tip, "flow node 0", options);
            }
            if (e.type != EventType.MouseDown) continue;
            if (!GUILayoutUtility.GetLastRect().Contains(e.mousePosition)) continue;
            if (object.ReferenceEquals(Tree, flow))
            {
                ShowTip(string.Format("{0},已经被选中,无需重复设置", Tree.name));
            }
            else
            {
                Tree = flow;
                ShowTip(string.Format("{0},被选中", Tree.name));
            }
            e.Use();
        }
    }

    private void DrawDebugState()
    {
        EditorGUILayout.Space();
        DrawDebugColor();
        EditorGUILayout.Space();
        DrawFlowCharts();
        EditorGUILayout.Space();
    }

    private void DrawPropertyView()
    {
        if (!NGUIEditorTools.DrawHeader("节点属性", "PropertyNode")) return;
        EditorGUIUtility.labelWidth = 80;
        propertyScroll = GUILayout.BeginScrollView(propertyScroll);
        if (DebugMode) GUI.enabled = false;
        tree.EditDrawProperty(this);
        if (DebugMode) GUI.enabled = true;
        GUILayout.FlexibleSpace();
        GUILayout.EndScrollView();
    }

    private void DrawBasicView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("基础节点", "BasicFTNode")) return;
        NGUIEditorTools.BeginContents();
        //DrawToolBtn<DebugFlowNode>("测试", style);

        DrawToolBtn<AOI>("碰撞触发器", style);
        DrawToolBtn<CircleTriggerNode>("探索触发器", style);
        DrawToolBtn<CircleTimerTriggerNode>("计时探索触发器", style);
        DrawToolBtn<OpenDoor>("打开门", style);
        DrawToolBtn<CloseDoor>("关闭门", style);
        DrawToolBtn<EndGame>("游戏结束", style);

        DrawToolBtn<SpawnResNode>("创建资源对象", style);
        DrawToolBtn<DelayNode>("延迟", style);
        DrawToolBtn<PreloadAreaNode>("区域预加载", style);
        DrawToolBtn<StopFlowChartNode>("停止<流程树>", style);
        DrawToolBtn<DisposeNode>("释放<流程节点>", style);
        DrawToolBtn<FlowChartDisposeNode>("释放<流程树>", style);
        DrawToolBtn<ChgCopyNode>("切换副本", style);
        NGUIEditorTools.EndContents();

    }

    private void DrawCountView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("计数节点", "CntFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<CounterNode>("计数", style);
        DrawToolBtn<RepeatNode>("重复执行", style);
        DrawToolBtn<DropCntNode>("掉落计数", style);
        NGUIEditorTools.EndContents();
    }

    private void DrawMssnView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("任务节点", "MssnFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<RunMssnNode>("执行任务", style);
        DrawToolBtn<MssnEndLsnrNode>("任务完成监听", style);
        NGUIEditorTools.EndContents();
    }

    private void DrawAIvView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("AI/单位相关", "AIFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<InputMgrNode>("玩家控制", style);
        DrawToolBtn<ActivePlayerNode>("玩家隐藏", style);
        DrawToolBtn<PlayerHorseNode>("上下马", style);
        DrawToolBtn<AutoHangupNode>("自动挂机", style);
        DrawToolBtn<HangupPauseNode>("自动挂机暂停", style);
        DrawToolBtn<SpawnNode>("AI出生点", style);
        DrawToolBtn<AIOnOff>("AI开关", style);
        DrawToolBtn<DisposeUnitTypeNode>("释放阵营单位", style);
        DrawToolBtn<UnitPropLsnrNode>("单位属性监听", style);
        DrawToolBtn<FocusAtkNode>("锁定攻击", style);
        DrawToolBtn<UnitResetToChildNode>("重置主角位置和子变换一致", style);
        NGUIEditorTools.EndContents();
    }

    private void DrawNavView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("导航相关", "NavFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<AutoNavPlayerNode>("玩家自动寻路", style);
        DrawToolBtn<NavPlayerNode>("导航玩家", style);
        DrawToolBtn<NavUnitsNode>("导航单位", style);
        DrawToolBtn<StopNavNode>("停止导航", style);
        DrawToolBtn<ObjPathNode>("对象路径移动", style);
        DrawToolBtn<UnitPathNode>("单位路径移动", style);

        NGUIEditorTools.EndContents();
    }

    private void DrawCamView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("相机相关", "CamFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<CamSettingNode>("相机设置", style);
        DrawToolBtn<CamActiveNode>("相机激活", style);
        DrawToolBtn<CamSettingResetNode>("还原相机设置", style);
        DrawToolBtn<CameraSlowDownNode>("相机慢镜头特效", style);
        DrawToolBtn<CamShakeNode>("相机振动特效", style);
        DrawToolBtn<CamCrossfadeNode>("相机淡入淡出特效", style);
        DrawToolBtn<CamHeightNode>("相机设置高度", style);
        DrawToolBtn<CamPathNode>("相机路径移动", style);
        DrawToolBtn<CamSwitchNode>("相机更新开关", style);
        DrawToolBtn<CamFollowSpeciNode>("相机跟随目标子节点", style);
        DrawToolBtn<FxBlurNode>("相机模糊", style);
        NGUIEditorTools.EndContents();
    }

    private void DrawEffectView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("特效相关", "EffectFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<SceneAnimLineNode>("场景时间线动画", style);
        DrawToolBtn<SceneAnimNode>("场景物体动画", style);
        DrawToolBtn<UnitAnimNode>("播放单位动画", style);
        DrawToolBtn<UnitFxNode>("单位绑定特效", style);
        DrawToolBtn<ActiveNode>("激活/隐藏物体", style);
        DrawToolBtn<UnitRotateNode>("单位旋转", style);
        DrawToolBtn<ObjRotateNode>("对象旋转", style);
        DrawToolBtn<TimeScaleNode>("时间缩放", style);
        NGUIEditorTools.EndContents();
    }

    private void DrawUIView(string style)
    {
        if (!NGUIEditorTools.DrawHeader("UI相关", "UIFTNode")) return;
        NGUIEditorTools.BeginContents();
        DrawToolBtn<BubbleNode>("气泡", style);
        DrawToolBtn<UISubTitleNode>("字幕", style);
        DrawToolBtn<DialogNode>("对话框", style);
        DrawToolBtn<BubbleComNode>("组件气泡", style);
        DrawToolBtn<UIActiveNode>("激活/隐藏窗口", style);
        DrawToolBtn<UICopyInfoMainOnNode>("打开副本信息", style);
        DrawToolBtn<UICopyInfoMainOffNode>("关闭副本信息", style);

        NGUIEditorTools.EndContents();
    }



    private void DrawBtnToolView()
    {

        EditorGUILayout.Space();
        if (!NGUIEditorTools.DrawHeader("流程节点", "ProcessNodes")) return;
        toolBtnScroll = EditorGUILayout.BeginScrollView(toolBtnScroll, GUILayout.Height(Win.position.height * 0.5f));
        if (DebugMode) GUI.enabled = false;
        DrawBasicView("flow node 0");

        EditorGUILayout.Space();
        DrawCountView("flow node 1");
        EditorGUILayout.Space();
        DrawMssnView("flow node 1");
        EditorGUILayout.Space();
        DrawAIvView("flow node 2");

        EditorGUILayout.Space();
        DrawNavView("flow node 3");

        EditorGUILayout.Space();
        DrawCamView("flow node 4");

        EditorGUILayout.Space();

        DrawEffectView("flow node 5");
        EditorGUILayout.Space();
        //DrawMisView("flow node 5");

        EditorGUILayout.Space();

        DrawUIView("flow node 5");

        EditorGUILayout.Space();
        if (DebugMode) GUI.enabled = true;

        EditorGUILayout.EndScrollView();
    }

    private void DrawToolBtn<T>(string chnName, string style) where T : FlowChartNode, new()
    {
        GUILayout.Space(3);
        GUILayout.Box(chnName, style, options);
        if (e.type != EventType.MouseDown) return;
        if (!GUILayoutUtility.GetLastRect().Contains(e.mousePosition)) return;
        Vector2 bornPos = new Vector2(10, e.mousePosition.y - toolBtnScroll.y + 15);
        tree.EditCreateNode<T>(this, bornPos);
        e.Use();
    }


    private void SaveTreeHaveDialog()
    {
        string tip = string.Format("需要保存流程树:{0}吗?", tree.name);
        if (EditorUtility.DisplayDialog("", tip, "确定", "取消"))
        { SaveTreeNoDialog(); }
        else { ShowTip("以取消"); }
    }
    private void SaveTreeNoDialog()
    {
        if (DebugMode) return;
        if (!tree.EditExistStartNode())
        { ShowTip("保存失败\n没有设置起点"); return; }
        Save();
        ShowTip("保存成功");

    }

    private void Save()
    {
        var view = Win.Get<TriggerSceneView>();
        var path = view.GetPath(Tree.name);
        tree.Save(path);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    private void BackUp()
    {
        string backUpDir = Directory.GetCurrentDirectory() + "/Backup/Trigger/";
        if (!Directory.Exists(backUpDir)) Directory.CreateDirectory(backUpDir);
        var assetDir = Win.Get<TriggerSceneView>().AssetDir;
        var fn = name + Suffix.Bytes;
        string sourcePath = Directory.GetCurrentDirectory() + "/" + assetDir + "/" + fn;
        string targetPath = backUpDir + fn;
        File.Copy(sourcePath, targetPath, true);
        ShowTip(string.Format("备份:{0}成功,目录:{1}", name, backUpDir));
    }


    private void ToggleTest()
    {
        EditorPrefs.SetBool("ShowTest", !EditorPrefs.GetBool("ShowTest"));
    }

    private void DrawTestContext()
    {
        if (!EditorPrefs.GetBool("ShowTest")) return;
        if (Tree != null) Tree.EditTestContext();
    }

    private void RegisterUndo()
    {
        if (Win != null) Win.Repaint();
    }

    /// <summary>
    /// 绘制工具栏
    /// </summary>
    private void DrawToolBar()
    {
        EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
        //if (EditorApplication.isPlaying)
        {
            if (GUILayout.Button("成功停止", EditorStyles.toolbarButton, tarOpt))
            {
                EndTree(1);
            }
            else if (GUILayout.Button("失败停止", EditorStyles.toolbarButton, tarOpt))
            {
                EndTree(0);
            }
        }
        GUILayout.FlexibleSpace();
        EditorGUILayout.EndHorizontal();
    }

    private bool CheckTree()
    {
        if (tree == null)
        {
            EditorUtility.DisplayDialog("", "没有选择任何流程树", "确定");
            return false;
        }
        return true;
    }

    #region 运行时交互
    /// <summary>
    /// 结束流程树 
    /// </summary>
    /// <param name="opt">0:失败,1:胜利</param>
    public void EndTree(int opt)
    {
        if (!CheckTree()) return;
        string des = opt == 0 ? "失败" : "胜利";
        string tName = Tree.name;
        string msg = string.Format("以【{0}】的方式停止流程树:{1}", des, tName);
        if (EditorUtility.DisplayDialog("", msg, "确定"))
        {
            List<EndGame> ends = Tree.FindNodes<EndGame>();
            if (ends == null)
            {
                msg = string.Format("{0},没有配置结束节点", tName);
                EditorUtility.DisplayDialog("", msg, "确定");
                return;
            }
            EndGame target = null;
            int length = ends.Count;
            for (int i = 0; i < length; i++)
            {
                EndGame item = ends[i];
                if (item.endOption != opt) continue;
                target = item; break;
            }
            if (target == null)
            {
                msg = string.Format("{0},没有配置选项【{1}】的结束节点", tName, des);
                EditorUtility.DisplayDialog("", msg, "确定");
            }
            else
            {
                target.EditCompleteDynamic();
            }
        }
    }
    #endregion
    #endregion

    #region 保护方法

    protected override void OpenCustom()
    {
        Win.SetTitle("编辑流程树窗口");
        Undo.undoRedoPerformed += RegisterUndo;
    }

    protected override void CloseCustom()
    {
        Undo.undoRedoPerformed -= RegisterUndo;
        if (tree == null) return;
        tree.EditClearUndo(this);
        tree.Dispose();
    }
    protected override void ContextClick()
    {
        if (e.type == EventType.ContextClick)
        {
            if (e.mousePosition.x < 300) return;
            GenericMenu menu = new GenericMenu();
            menu.AddSeparator("");
            menu.AddItem("定位流程树", false, PingTree);
            if (!DebugMode)
            {
                menu.AddSeparator("");
                menu.AddItem("设置为起点", false, SetStartNode);
                menu.AddSeparator("");
                menu.AddItem("复制节点", false, CopyNode);
                menu.AddSeparator("");
                menu.AddItem("保存", false, SaveTreeHaveDialog);
                menu.AddSeparator("");
                menu.AddItem("备份", false, BackUp);
                menu.AddSeparator("");
                menu.AddItem("返回", false, Return);
            }

            menu.ShowAsContext();
        }
    }
    protected override void OnGUICustom()
    {
        ContextClick();
        DrawToolBar();
        EditorGUILayout.BeginHorizontal("flow background", GUILayout.MinHeight(Win.position.height));

        EditorGUILayout.BeginVertical("flow background", GUILayout.Width(nodeAreaWidth), GUILayout.MinHeight(Win.position.height));
        EditorGUILayout.Space();

        if (DebugMode)
        {
            DrawDebugState();
        }
        else
        {
            DrawBtnToolView();
        }
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        if (tree != null)
        {
            DrawPropertyView();
        }

        EditorGUILayout.EndVertical();
        if (tree != null)
        {
            DrawTestContext();
            nodeArea.Set(nodeAreaWidth, 0, Win.position.width, Win.position.height);
            GUILayout.BeginArea(nodeArea);
            tree.EditDrawTree(e, this);
            UIEditLayout.HelpWaring("编辑过程中不要切换场景");
            GUILayout.EndArea();
        }
        EditorGUILayout.EndHorizontal();

    }
    #endregion

    #region 公开方法
    public void EditTree(FlowChart fc)
    {
        if (fc == null)
        {
            EditorUtility.DisplayDialog("警告", "编辑对象不存在", "OK");
            Win.Close();
        }
        else
        {
            Tree = fc;
        }
    }

    public override void OnSceneGUI(SceneView view)
    {
        if (tree == null) return;
        if (e == null) return;
        tree.EditDrawSceneGUI(this);
    }


    protected override void OnDestroyCustom()
    {
        Undo.undoRedoPerformed -= RegisterUndo;
        if (DebugMode) return;
        if (tree == null) return;
        if (tree.Root == null) return;
        Loong.Game.iTool.Destroy(tree.Root.gameObject);
    }

    #endregion
}