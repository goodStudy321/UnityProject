using System;
using Phantom;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using System.Diagnostics;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;
using Random = UnityEngine.Random;
using Object = UnityEngine.Object;
#if UNITY_EDITOR
using UnityEditor;
#endif

/*
 * Loong 于2015.11.11-13 优化,重构,注释
 * Loong 于2015.02.25-26 优化,添加回退功能,重命名Ed_为Edit
 */

namespace Phantom
{

    /// <summary>
    /// 流程节点基类
    /// </summary>
    [Serializable]
    public class FlowChartNode : IComparer<FlowChartNode>, IComparable<FlowChartNode>
    {
        /// <summary>
        /// 脉冲类型
        /// </summary>
        public enum PulseType
        {
            /// <summary>
            /// 所有
            /// </summary>
            All,
            /// <summary>
            /// 选择
            /// </summary>
            Switch,
            /// <summary>
            /// 随机
            /// </summary>
            Random
        }


        #region 字段
        private FlowChart mFlowChart;


        private TransitionState transition;

        protected List<FlowChartLink> inputLinks;
        protected List<FlowChartLink> outputLinks;

        [HideInInspector]
        public Vector2 pos;

        [SerializeField]
        protected PulseType outType;
        [SerializeField]
        protected PulseType inType;
        [SerializeField]
        protected int inNum = 1;
        [SerializeField]
        protected int outNum = 1;
        [SerializeField]
        protected string style = "flow node 0";

        public string name = "";
        #endregion

        #region 属性

        /// <summary>
        /// 流程树
        /// </summary>
        public FlowChart flowChart
        {
            get { return mFlowChart; }
            set { mFlowChart = value; }
        }

        /// <summary>
        /// 节点运行状态
        /// </summary>
        public TransitionState Transition
        {
            get { return transition; }
            set { transition = value; }
        }


        #endregion

        #region 委托事件
        /// <summary>
        /// 结束事件
        /// </summary>
        public event Action<FlowChartNode> complete = null;
        #endregion

        #region 私有方法
        /// <summary>
        /// 所有的子节点都要准备好
        /// </summary>
        private bool ReadyAll()
        {
            int length = inputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                if (inputLinks[i].start.Transition != TransitionState.Complete)
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// 被选中的都要准备好
        /// </summary>
        private bool ReadySwitch()
        {
            int length = inputLinks.Count;
            FlowChartLink link = null;
            for (int i = 0; i < length; i++)
            {
                link = inputLinks[i];
                if (link.inTog &&
                    link.start.Transition != TransitionState.Complete)
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// 准备好的数量满足一个数即可
        /// </summary>
        private bool ReadyRandom()
        {
            int length = inputLinks.Count;
            int completeNum = 0;
            FlowChartLink link = null;
            for (int i = 0; i < length; i++)
            {
                link = inputLinks[i];
                if (link.inTog &&
                    link.start.Transition == TransitionState.Complete)
                {
                    completeNum++;
                }
            }
            if (completeNum < inNum) return false;
            return true;
        }

        /// <summary>
        /// 所有输出
        /// </summary>
        private void OutputAll()
        {
            int length = outputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                outputLinks[i].end.StartProcess();
            }
        }



        /// <summary>
        /// 随机输出
        /// </summary>
        private void OutputSwitch()
        {
            FlowChartLink link = null;
            int length = outputLinks.Count;
            for (int i = 0; i < outNum; i++)
            {
                int totalWeight = 0;
                for (int j = 0; j < length; j++)
                {
                    link = outputLinks[j];
                    if (link.outTog &&
                        link.end.Transition == TransitionState.Wait)
                    {
                        totalWeight += outputLinks[j].outWt;
                    }
                }
                int weight = Random.Range(0, totalWeight);
                for (int j = 0; j < length; j++)
                {
                    link = outputLinks[j];
                    if (link.outTog &&
                       link.end.Transition == TransitionState.Wait)
                    {
                        weight -= link.outWt;
                        if (weight <= 0)
                        {
                            outputLinks[j].end.StartProcess();
                            break;
                        }
                    }
                }
            }
        }
        #endregion

        /// <summary>
        /// 进入节点
        /// </summary>
        private void ProcessReady()
        {
            bool complete = false;
            if (inType == PulseType.All)
            {
                complete = ReadyAll();
            }
            else if (inType == PulseType.Switch)
            {
                complete = ReadySwitch();
            }
            else if (inType == PulseType.Random)
            {
                complete = ReadyRandom();
            }

            if (complete)
            {
#if UNITY_EDITOR
                if (mFlowChart != null)
                {
                    mFlowChart.EditRepaint();
                    mFlowChart.EditAddDynamic(this);
                }
#endif
                Transition = TransitionState.Update;
                ReadyCustom();
            }
        }

        #region 保护方法

        /// <summary>
        /// 自定义成功进入
        /// </summary>
        protected virtual void ReadyCustom()
        {

        }

        /// <summary>
        /// 更新节点
        /// </summary>
        protected virtual void ProcessUpdate()
        {

        }
        /// <summary>
        /// 结束节点
        /// </summary>
        protected void Complete()
        {
#if UNITY_EDITOR
            if (mFlowChart != null)
            {
                mFlowChart.EditRepaint();
                mFlowChart.EditRemoveDynamic(name);
            }
#endif
            Transition = TransitionState.Complete;
            mFlowChart.SetRunning();
            CompleteCustom();
            if (complete != null) complete(this);
        }
        /// <summary>
        /// 自定义结束
        /// </summary>
        protected virtual void CompleteCustom()
        {
            if (outputLinks == null) return;
            if (outType == PulseType.All)
            {
                OutputAll();
            }
            else if (outType == PulseType.Switch)
            {
                OutputSwitch();
            }
        }

        #endregion

        #region 公开方法

        /// <summary>
        /// 检查有效性
        /// </summary>
        /// <returns></returns>
        public virtual bool Check()
        {
            return true;
        }
        /// <summary>
        /// 预加载
        /// </summary>
        public virtual void Preload()
        {

        }

        public virtual void Read(BinaryReader br)
        {
            ExVector.Read(ref pos, br);
            outType = (PulseType)br.ReadInt32();
            inType = (PulseType)br.ReadInt32();
            inNum = br.ReadInt32();
            outNum = br.ReadInt32();
            //style = br.ReadString();
            //name = br.ReadString();
            ExString.Read(ref style, br);
            ExString.Read(ref name, br);
        }

        public virtual void Write(BinaryWriter bw)
        {
            var type = this.GetType().FullName;
            ExString.Write(type, bw);
            //bw.Write(type);
            pos.Write(bw);
            bw.Write((int)outType);
            bw.Write((int)inType);
            bw.Write(inNum);
            bw.Write(outNum);
            //bw.Write(style);
            //bw.Write(name);
            ExString.Write(style, bw);
            ExString.Write(name, bw);
        }


        /// <summary>
        /// 通过根节点发现子节点,如果不存在则创建
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public virtual Transform FindOrCreate(string name)
        {
            var root = flowChart.Root;
            var c = root.Find(name);
            if (c == null)
            {
                var go = new GameObject(name);
                c = go.transform;
                c.parent = root;
            }
            return c;
        }

        public GameObject FindOrCreateGo(string name)
        {
            var tran = FindOrCreate(name);
            return tran.gameObject;
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void Initialize()
        {
            Transition = TransitionState.Wait;
            if (mFlowChart == null) return;
            inputLinks = mFlowChart.FindLinkByEndNode(this);
            outputLinks = mFlowChart.FindLinkByStartNode(this);

        }
        /// <summary>
        /// 重置
        /// </summary>
        public virtual void Reset()
        {
#if UNITY_EDITOR
            if (mFlowChart != null) mFlowChart.EditRepaint();
#endif
            Transition = TransitionState.Wait;
        }
        /// <summary>
        /// 更新
        /// </summary>
        public void Execute()
        {
            switch (Transition)
            {
                case TransitionState.Ready:
                    ProcessReady();
                    break;
                case TransitionState.Update:
                    ProcessUpdate();
                    break;
            }
        }

        /// <summary>
        /// 重置子节点
        /// </summary>
        public void ResetChildren()
        {
            int length = outputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                outputLinks[i].start.Reset();
            }
        }
        /// <summary>
        /// 开始流程
        /// </summary>
        public void StartProcess()
        {
            if (Transition != TransitionState.Wait) return;
#if UNITY_EDITOR
            if (mFlowChart != null) mFlowChart.EditRepaint();
#endif
            Transition = TransitionState.Ready;
        }
        /// <summary>
        /// 停止流程
        /// </summary>
        public virtual void Stop()
        {
#if UNITY_EDITOR
            if (mFlowChart != null) mFlowChart.EditRepaint();
#endif
            Transition = TransitionState.Stop;
        }

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {

        }


        public virtual List<string> GetResourcesID()
        {
            return null;
        }

        /// <summary>
        /// 获取指定类型的上一级节点
        /// </summary>
        public virtual T GetInputNode<T>(List<FlowChartLink> lst) where T : FlowChartNode
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                if (lst[i].start is T)
                {
                    T t = lst[i].start as T;
                    return t;
                }
            }
            return null;
        }

        /// <summary>
        /// 获取指定类型的下一级节点
        /// </summary>
        public virtual T GetOutNode<T>(List<FlowChartLink> lst) where T : FlowChartNode
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                if (lst[i].end is T)
                {
                    T t = lst[i].end as T;
                    return t;
                }
            }
            return null;
        }

        /// <summary>
        /// 设置输入节点状态
        /// </summary>
        /// <param name="state">状态</param>
        public void SetInputNode(TransitionState state)
        {
            int length = inputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = inputLinks[i];
                link.start.Transition = state;
            }
        }

        /// <summary>
        /// 格式化提示消息
        /// </summary>
        /// <param name="fmt">提示信息</param>
        /// <returns></returns>
        public string Format(string fmt, params object[] args)
        {
            var sb = new StringBuilder();
            sb.Append("Loong: ");
#if UNITY_EDITOR
            sb.Append(DateTime.Now.ToString("[HH:mm:ss fff]  "));
#endif
            sb.Append("FlowTree:").Append(flowChart.name);
            sb.Append(", type:").Append("<").Append(this.GetType().Name).Append(">");
            sb.Append(", node:").Append(name);
            sb.Append(", info:");
            if (args == null || args.Length < 1)
            {
                sb.Append(fmt);
            }
            else
            {
                sb.AppendFormat(fmt, args);
            }
            return sb.ToString();
        }

        public int CompareTo(FlowChartNode other)
        {
            return this.pos.x.CompareTo(other.pos.x);
        }

        public int Compare(FlowChartNode f1, FlowChartNode f2)
        {
            return f1.CompareTo(f2);
        }

        public void Log(string msg)
        {
            Debug.Log(Format(msg));
        }

        public void LogWarning(string msg)
        {
            Debug.LogWarning(Format(msg));
        }

        public void LogError(string msg)
        {
            Debug.LogError(Format(msg));
        }

        [Conditional("UNITY_EDITOR")]
        public void EditorLog(string msg)
        {
            Log(msg);
        }

        [Conditional("UNITY_EDITOR")]
        public void EditorLogWarning(string msg)
        {
            LogWarning(msg);
        }

        [Conditional("UNITY_EDITOR")]
        public void EditorLogError(string msg)
        {
            LogError(msg);
        }

        #endregion

        #region 编辑器/字段/属性/方法
#if UNITY_EDITOR

        #region 字段
        private Rect nodeArea = new Rect(0, 0, 0, 0);
        private Rect flagArea = new Rect(0, 0, 0, 0);
        private Rect editInputArea = new Rect(0, 0, 16, 16);
        private Rect editOutputArea = new Rect(0, 0, 16, 16);
        protected Event e;
        protected int placeIndex;
        protected float linkSize = 16;
        protected Vector2 dragStartPos;
        protected string realStyle;

        [NonSerialized]
        [HideInInspector]
        public bool editSelect;
        [NonSerialized]
        [HideInInspector]
        public Vector2 editSize = new Vector2(100, 30);


        #endregion

        #region 属性
        public virtual bool CanFlag
        {
            get { return false; }
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// Loong 绘制场景图标
        /// </summary>
        private void OnDrawGizmos()
        {
            if (Application.isPlaying) return;
            if (mFlowChart == null) return;
            EditGizmosUpdate();
        }


        /// <summary>
        /// Loong 更新区域坐标
        /// </summary>
        private void EditUpdateArea()
        {
            nodeArea.x = pos.x;
            nodeArea.y = pos.y;
            nodeArea.width = editSize.x;
            nodeArea.height = editSize.y;

            float x = nodeArea.center.x - linkSize * 0.5f;
            flagArea.x = pos.x - linkSize;
            flagArea.y = nodeArea.center.y - linkSize * 0.5f;

            flagArea.width = linkSize;
            flagArea.height = linkSize;


            editInputArea.x = x;
            editInputArea.y = nodeArea.y - linkSize;

            editInputArea.width = linkSize;
            editInputArea.height = linkSize;

            editOutputArea.x = nodeArea.center.x - linkSize * 0.5f;
            editOutputArea.y = nodeArea.max.y;

            editOutputArea.width = linkSize;
            editOutputArea.height = linkSize;
        }

        #endregion

        #region 保护方法

        /// <summary>
        /// 绘制控制UI
        /// </summary>
        protected virtual void EditDrawCtrlUI(Object o)
        {

        }

        /// <summary>
        /// 绘制Debug区域
        /// </summary>
        protected virtual void EditDrawDebug(Object o)
        {

        }


        /// <summary>
        /// 绘制场景图标可重写
        /// </summary>
        protected virtual void EditGizmosUpdate()
        {

        }

        protected virtual void EditDrawInputCustom()
        {
            inType = (PulseType)EditorGUILayout.EnumPopup(
                      "输入模式", inType);
            if (flowChart == null) { GUILayout.EndVertical(); return; }
            List<FlowChartLink> links = mFlowChart.FindLinkByEndNode(this);
            GUILayout.Space(10);
            if (inType == PulseType.All)
            {
                EditorGUILayout.HelpBox("等待所有的输入节点都完成,才进入此节点", MessageType.Info);
            }
            else if (inType == PulseType.Switch)
            {
                EditorGUILayout.HelpBox("等待选择的输入节点都完成,才进入此节点", MessageType.Info);
                int length = links.Count;
                for (int i = 0; i < length; i++)
                {
                    GUILayout.BeginHorizontal("flow overlay box");
                    links[i].inTog = EditorGUILayout.Toggle(
                        links[i].inTog, GUILayout.Width(20));
                    EditorGUILayout.LabelField(
                        links[i].start.name);
                    GUILayout.EndHorizontal();
                    GUILayout.Space(5);
                }
            }
            else if (inType == PulseType.Random)
            {
                int linkMax = 0;
                int length = links.Count;
                for (int i = 0; i < length; i++)
                {
                    if (links[i].inTog) linkMax++;
                }
                inNum = EditorGUILayout.IntSlider(
                    "输入数量", inNum, 1, linkMax);
                for (int i = 0; i < length; i++)
                {
                    GUILayout.BeginHorizontal("flow overlay box");
                    links[i].inTog = EditorGUILayout.Toggle(
                        links[i].inTog, GUILayout.Width(20));
                    EditorGUILayout.LabelField(
                        links[i].start.name);

                    GUILayout.EndHorizontal();
                    GUILayout.Space(5);
                }
            }
        }

        protected virtual void EditDrawOutputCustom(Object o)
        {
            outType = (PulseType)EditorGUILayout.EnumPopup(
                       "输出模式", outType);
            if (flowChart == null) { GUILayout.EndVertical(); return; }
            List<FlowChartLink> links = mFlowChart.FindLinkByStartNode(this);
            GUILayout.Space(10);
            if (outType == PulseType.All)
            {
                EditorGUILayout.HelpBox("将进入所有的输出节点", MessageType.Info);
            }
            else if (inType == PulseType.Switch)
            {
                int linkMax = 0;
                int length = links.Count;
                for (int i = 0; i < length; i++)
                {
                    if (links[i].outTog) linkMax++;
                }
                outNum = EditorGUILayout.IntSlider(
                    "输出数量", outNum, 1, linkMax);
                for (int i = 0; i < length; i++)
                {
                    GUILayout.BeginHorizontal("flow overlay box");
                    links[i].outTog = EditorGUILayout.Toggle(
                        links[i].outTog, GUILayout.Width(20));
                    EditorGUILayout.LabelField(
                        links[i].end.name);
                    if (links[i].outTog)
                    {
                        links[i].outWt = EditorGUILayout.IntField(
                            links[i].outWt);
                    }
                    GUILayout.EndHorizontal();

                    GUILayout.Space(5);
                }
            }
        }

        /// <summary>
        /// 自定义停止动态节点
        /// </summary>
        protected virtual void EditCompleteDynamicCustom()
        {

        }

        #endregion

        #region 公开方法

        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void EditInitialize()
        {

        }

        /// <summary>
        /// 更新配置
        /// </summary>
        public virtual void EditRefresh()
        {

        }

        /// <summary>
        /// 清除撤销
        /// </summary>
        public virtual void EditClearUndo(Object o)
        {
            Undo.ClearUndo(o);
        }

        /// <summary>
        /// 设置起点样式
        /// </summary>
        public void EditSetStartStyle(bool active, Object o)
        {
            EditUtil.RegisterUndo("SetStart", o);
            if (active)
            {
                if (style.Contains("node hex hex"))
                {
                    style = style.Replace("node hex hex", "node hex");
                }
                else if (style.Contains("node hex"))
                {
                    return;
                }
                else if (style.Contains("node"))
                {
                    style = style.Replace("node", "node hex");
                }
            }
            else
            {
                style = style.Replace("node hex", "node");
            }
        }

        /// <summary>
        /// 输入中心位置
        /// </summary>
        public Vector2 EditInputCenter()
        {
            return editInputArea.center;
        }

        /// <summary>
        /// 输出中心位置
        /// </summary>
        public Vector2 EditOutputCenter()
        {
            return editOutputArea.center;
        }

        /// <summary>
        /// 判断区域是否包含一个点
        /// </summary>
        public bool EditAreaContains(Vector2 pos)
        {
            return nodeArea.Contains(pos);
        }

        /// <summary>
        /// 判断输入区域是否包含一个点
        /// </summary>
        public bool EditInputAreaContains(Vector2 pos)
        {
            return editInputArea.Contains(pos);
        }

        /// <summary>
        /// 判断输出区域是否包含一个点
        /// </summary>
        public bool EditOutputAreaContains(Vector2 pos)
        {
            return editOutputArea.Contains(pos);
        }

        /// <summary>
        /// 区域是否与另一个区域重叠
        /// </summary>
        public bool EditHitNodeArea(Rect pos)
        {
            return nodeArea.Overlaps(pos);
        }

        /// <summary>
        /// 输入区域是否与另一个区域重叠
        /// </summary>
        public bool EditHitInputArea(Rect pos)
        {
            return editInputArea.Overlaps(pos);
        }

        /// <summary>
        /// 输出区域是否与另一个区域重叠
        /// </summary>
        public bool EditHitOutputArea(Rect pos)
        {
            return editOutputArea.Overlaps(pos);
        }


        /// <summary>
        /// 点击节点按钮
        /// </summary>
        public virtual void EditClickNode()
        {

        }

        /// <summary>
        /// 绘制点
        /// </summary>
        /// <param name="ev"></param>
        public void EditDrawNode(Event ev)
        {
            e = ev;
            EditUpdateArea();

            GUI.backgroundColor = Color.white;
            realStyle = editSelect ? (style + " on") : style;


            if (Application.isPlaying)
            {
                switch (Transition)
                {
                    case TransitionState.Wait:
                        realStyle = "flow node 3";
                        break;
                    case TransitionState.Ready:
                        realStyle = "flow node 1";
                        break;
                    case TransitionState.Update:
                        realStyle = "flow node 4";
                        break;
                    case TransitionState.Complete:
                        realStyle = "flow node 0";
                        break;
                    case TransitionState.Stop:
                        realStyle = "flow node 6";
                        break;
                }
            }
            GUI.Box(nodeArea, name, realStyle);
            var radio = GUI.skin.GetStyle("Radio");
            if (!mFlowChart.EditCheckStartNode(this)) GUI.Box(editInputArea, "", radio);
            GUI.Box(editOutputArea, "", radio);
            if (CanFlag) GUI.Box(flagArea, "", StyleTool.RedX);
            GUI.backgroundColor = Color.white;
        }

        public void EditDrawInputMode()
        {
            if (GUILayout.Button("节点输入"))
            {
                bool val = !EditorPrefs.GetBool("FlowCharNodeInputModeToggle");
                EditorPrefs.SetBool("FlowCharNodeInputModeToggle", val);
            }
            if (!EditorPrefs.GetBool("FlowCharNodeInputModeToggle")) return;
            GUILayout.BeginVertical("box", GUILayout.MinHeight(40));
            EditDrawInputCustom();
            GUILayout.EndVertical();
        }

        public void EditDrawOutputMode(Object o)
        {
            if (GUILayout.Button("节点输出"))
            {
                bool val = !EditorPrefs.GetBool("FlowCharNodeOutputModeToggle");
                EditorPrefs.SetBool("FlowCharNodeOutputModeToggle", val);
            }
            if (!EditorPrefs.GetBool("FlowCharNodeOutputModeToggle")) return;
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.MinHeight(40));
            EditDrawOutputCustom(o);
            GUILayout.EndVertical();
        }


        /// <summary>
        /// 记录拖动起始位置
        /// </summary>
        public void EditRecordDragBeg()
        {
            dragStartPos = pos;
        }

        /// <summary>
        /// 注册拖动撤销操作
        /// </summary>
        public void EditRecordUndoDrag(Object o)
        {
            Vector2 temp = pos;
            pos = dragStartPos;
            EditUtil.RegisterUndo("Move", o);
            pos = temp;
        }

        /// <summary>
        /// 在场景视图中固定流程点
        /// </summary>
        public virtual void EditHitSceneView(Object o)
        {

        }

        /// <summary>
        /// 复制方法
        /// </summary>
        public virtual void EditCopy(FlowChartNode other)
        {

        }

        /// <summary>
        /// 创建节点时调用
        /// </summary>
        public virtual void EditCreate()
        {

        }

        /// <summary>
        /// 在场景视图中绘制UI
        /// </summary>
        public virtual void EditDrawSceneGui(Object o)
        {

            Handles.BeginGUI();
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.BeginVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.BeginVertical(GUI.skin.window, GUILayout.Width(180));
            EditorGUILayout.Space();
            if (GUILayout.Button("聚焦:" + name)) { EditClickNode(); }
            EditorGUILayout.Space();
            EditDrawCtrlUI(o);
            EditorGUILayout.Space();
            GUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.EndVertical();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndHorizontal();
            Handles.EndGUI();
        }

        /// <summary>
        /// 绘制属性
        /// </summary>
        public virtual void EditDrawProperty(Object o)
        {
            GUILayout.Space(20);
            if (flowChart == null)
            {
                UIEditLayout.HelpInfo("没有指定流程树");
            }
            EditorGUILayout.BeginVertical("box");
            name = EditorGUILayout.TextField("名称:", name);
            GUILayout.Space(5);
            EditDrawInputMode();
            GUILayout.Space(5);
            EditDrawOutputMode(o);
            EditorGUILayout.EndVertical();
            GUILayout.Space(20);
            if (Application.isPlaying)
            {
                EditorGUILayout.BeginVertical(StyleTool.Box);
                EditorGUILayout.LabelField("Debug区域:");
                GUI.enabled = false;
                EditDrawDebug(o);
                GUI.enabled = true;
                EditorGUILayout.EndVertical();
            }
        }

        /// <summary>
        /// 停止动态节点
        /// </summary>
        public void EditCompleteDynamic()
        {
            if (!Application.isPlaying) return;
            Complete();
            EditCompleteDynamicCustom();
        }
        #endregion

#endif
        #endregion
    }
}