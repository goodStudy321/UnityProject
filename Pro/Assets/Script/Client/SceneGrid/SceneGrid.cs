using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格数据
    /// </summary>
    public class SceneGrid : ScriptableObject, IDisposable
    {
        #region 字段
        private int range = 1;

        [SerializeField]
        private int rowMax = 8;

        [SerializeField]
        private int columnMax = 8;

        private float nodeWidth = 0;

        private float nodeHeight = 0;

        private float nodeWidthInverse = 0;

        private float nodeHeightInverse = 0;

        private Transform target = null;

        private SceneGridNode last = null;

        private SceneGridNode current = null;

        private ProcessState state = ProcessState.None;

        [SerializeField]
        private Vector3 rightUpPoint = new Vector3(40, 0, 40);

        [SerializeField]
        private Vector3 leftDownPoint = new Vector3(-40, 0, -40);

        private List<SceneGridNode> nodes = new List<SceneGridNode>();

        [SerializeField]
        private List<GridNodeGbjInfo> menualInfos = new List<GridNodeGbjInfo>();

        /// <summary>
        /// 节点字典 键:行和列获取的唯一值 值:节点
        /// </summary>
        private Dictionary<int, SceneGridNode> nodeDic = new Dictionary<int, SceneGridNode>();
        #endregion

        #region 属性

        /// <summary>
        /// 范围最小值1,
        /// 以当前节点为中心,扩大Range圈
        /// 所以1时 是九宫格 2时是25宫格
        /// </summary>
        public int Range
        {
            get { return range; }
            set { range = (value < 1) ? 1 : value; }
        }

        /// <summary>
        /// 最大行号
        /// </summary>
        public int RowMax
        {
            get { return rowMax; }
            set { rowMax = value; }
        }

        /// <summary>
        /// 最大列号
        /// </summary>
        public int ColumnMax
        {
            get { return columnMax; }
            set { columnMax = value; }
        }

        /// <summary>
        /// 节点宽度
        /// </summary>
        public float NodeWidth
        {
            get { return nodeWidth; }
        }

        /// <summary>
        /// 节点长度
        /// </summary>
        public float NodeHeight
        {
            get { return nodeHeight; }
        }

        /// <summary>
        /// 节点宽度的倒数
        /// </summary>
        public float NodeWidthInverse
        {
            get { return nodeWidthInverse; }
        }

        /// <summary>
        /// 节点高度的倒数
        /// </summary>
        public float NodeHeightInverse
        {
            get { return nodeHeightInverse; }
        }



        /// <summary>
        /// 左下角点
        /// </summary>
        public Vector3 LeftDownPoint
        {
            get { return leftDownPoint; }
            set { leftDownPoint = value; }
        }

        /// <summary>
        /// 右上角点
        /// </summary>
        public Vector3 RightUpPoint
        {
            get { return rightUpPoint; }
            set { rightUpPoint = value; }
        }

        /// <summary>
        /// 目标和九宫状态
        /// </summary>
        public ProcessState State
        {
            get { return state; }
            set { state = value; }
        }
        /// <summary>
        /// 上一个节点
        /// </summary>
        public SceneGridNode Last
        {
            get { return last; }
            set { last = value; }
        }

        /// <summary>
        /// 判定目标
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; }
        }

        /// <summary>
        /// 当前节点
        /// </summary>
        public SceneGridNode Current
        {
            get { return current; }
            set
            {
                Last = current;
                current = value;
                SetCurrentActive();
            }
        }

        /// <summary>
        /// 所有九宫格节点
        /// </summary>
        public List<SceneGridNode> Nodes
        {
            get { return nodes; }
            set { nodes = value; }
        }

        /// <summary>
        /// 手动添加的游戏对象信息
        /// </summary>
        public List<GridNodeGbjInfo> MenualInfos
        {
            get { return menualInfos; }
            set { menualInfos = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public SceneGrid()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 根据目标点Z轴与左下角点Z轴距离计算得出行号
        /// </summary>
        /// <param name="ldPointZ">左下角点Z轴</param>
        /// <param name="targetZ">目标点Z轴</param>
        /// <returns></returns>
        private int GetRow(float ldPointZ, float targetZ)
        {
            float disZ = targetZ - ldPointZ;
            int row = Mathf.FloorToInt(disZ * nodeHeightInverse);
            return row;
        }

        /// <summary>
        /// 根据目标点X轴与左下角点X轴距离计算得出列号
        /// </summary>
        /// <param name="ldPointX">左下角点X轴</param>
        /// <param name="targetX">目标点X轴</param>
        /// <returns></returns>
        private int GetCol(float ldPointX, float targetX)
        {
            float disX = targetX - leftDownPoint.x;
            int col = Mathf.FloorToInt(disX * nodeWidthInverse);
            return col;
        }

        #region 属性设置
        /// <summary>
        /// 将场景中SceneRoot节点下所有游戏对象根据位置自动添加到九宫格中
        /// </summary>
        private void Add(Transform root)
        {
            Vector3 ruPoint = RightUpPoint;
            Vector3 ldPoint = LeftDownPoint;
            int length = root.childCount;
            for (int i = 0; i < length; i++)
            {
                Transform child = root.GetChild(i);
                Add(child.gameObject);
            }
        }

        /// <summary>
        /// 将手动添加的游戏对象添加到制定九宫格中
        /// </summary>
        private void AddMenual(Transform root)
        {
            int length = menualInfos.Count;
            for (int i = 0; i < length; i++)
            {
                GridNodeGbjInfo info = menualInfos[i];
                Transform child = root.Find(info.Path);
                if (child == null) continue;
                Add(child.gameObject, info.pos);
            }
        }

        /// <summary>
        /// 设置节点
        /// </summary>
        private void SetNodes()
        {
            int length = Nodes.Count;
            for (int i = 0; i < length; i++)
            {
                nodes[i].Init();
            }
        }


        /// <summary>
        /// 创建节点
        /// </summary>
        private void CreateNodes()
        {
            Vector3 ldPoint = LeftDownPoint;
            Vector3 ruPoint = RightUpPoint;
            Vector3 ld = Vector3.zero;
            Vector3 ru = Vector3.zero;
            for (int row = 0; row < RowMax; row++)
            {
                for (int col = 0; col < ColumnMax; col++)
                {
                    SceneGridNode node = ObjPool.Instance.Get<SceneGridNode>();
                    node.Row = row; node.Column = col;
                    ld.x = ldPoint.x + nodeWidth * col;
                    ld.z = ldPoint.z + nodeHeight * row;
                    ru.x = ldPoint.x + nodeWidth * (col + 1);
                    ru.z = ldPoint.z + nodeHeight * (row + 1);
                    node.LeftDownPoint = ld;
                    node.RightUpPoint = ru;
                    node.Grid = this;
                    Nodes.Add(node);
                }
            }
        }

        /// <summary>
        /// 设置字典
        /// </summary>
        private void SetNodeDic()
        {
            nodeDic.Clear();
            int length = Nodes.Count;
            for (int i = 0; i < length; i++)
            {
                SceneGridNode node = Nodes[i];
                int id = node.ID;
                if (nodeDic.ContainsKey(id))
                {
                    SceneGridNode n1 = nodeDic[id];
                    LogError(string.Format("已经包含ID为:{0}的节点:{1},无法添加节点:{2}", id, n1, node));
                }
                else
                {
                    nodeDic.Add(id, node);
                }
            }
        }

        /// <summary>
        /// 设置宽高
        /// </summary>
        private void SetWidthHeight()
        {
            if (rowMax == 0) return;
            if (columnMax == 0) return;
            nodeWidth = (rightUpPoint.x - leftDownPoint.x) / columnMax;
            nodeHeight = (rightUpPoint.z - leftDownPoint.z) / rowMax;
            nodeWidthInverse = 1 / nodeWidth;
            nodeHeightInverse = 1 / nodeHeight;
        }
        #endregion

        #region 状态判定
        private bool Contains()
        {
            if (target == null) return false;
            if (AreaTool.Contains(leftDownPoint, rightUpPoint, target.position)) return true;
            return false;
        }

        private void None()
        {
            if (!Contains()) return;
            SetActive(false);
            Current = Get(target.position);
            if (Current == null)
            {
                LogError(string.Format("目标:{0},位置:{1},没有发现九宫格节点", target.name, target.position));
            }
            else
            {
                State = ProcessState.Enter;
            }
        }

        private void Enter()
        {
            iTrace.eLog("Loong", string.Format("目标:{0},进入九宫格节点:{1}", Target.name, Current.ToString()));
        }

        private void Execute()
        {
            if (Contains())
            {
                int col = GetCol(leftDownPoint.x, target.position.x);
                int row = GetRow(leftDownPoint.z, target.position.z);
                if (row != Current.Row || col != Current.Column)
                {
                    Current = Get(row, col);
                    if (Current == null)
                    {
                        LogError(string.Format("没有发现索引为:[{0},{1}]的节点", row, col));
                        State = ProcessState.Exit;
                    }
                }
            }
            else
            {
                State = ProcessState.Exit;
            }
        }

        private void Exit()
        {
            Last = Current;
            Current = null;
            if (Target == null)
            {
                iTrace.eLog("Loong", "目标不存在,退出九宫格检查");
            }
            else
            {
                iTrace.eLog("Loong", string.Format("目标:{0},离开九宫格范围", Target.name));
            }
        }

        /// <summary>
        /// 设置当前节点激活/隐藏
        /// </summary>
        private void SetCurrentActive()
        {
            if (Current == null)
            {
                return;
            }
            if (Last == null)
            {
                Current.SetGridActive(true);
            }
            else
            {
                Current.SetGridActive(Last, true);
                Last.SetGridActive(Current, false);
            }
        }
        #endregion
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 初始化
        /// </summary>
        public void Init()
        {
            Transform root = SceneGridMgr.Root;
            if (root == null) return;
            SetWidthHeight();
            CreateNodes();
            SetNodeDic();
            SetNodes();
            AddMenual(root);
            Add(root);
        }

        /// <summary>
        /// 更新
        /// </summary>
        public void Update()
        {
            switch (state)
            {
                case ProcessState.None:
                    None();
                    break;
                case ProcessState.Enter:
                    Enter();
                    State = ProcessState.Execute;
                    break;
                case ProcessState.Execute:
                    Execute();
                    break;
                case ProcessState.Exit:
                    Exit();
                    State = ProcessState.None;
                    break;
                default: break;
            }
        }

        /// <summary>
        /// 释放
        /// </summary>
        public void Dispose()
        {
            while (nodes.Count != 0)
            {
                SceneGridNode node = nodes[0];
                nodes.RemoveAt(0);
                node.Dispose();
                ObjPool.Instance.Add(node);
            }
            nodeDic.Clear();
        }

        /// <summary>
        /// 检查索引有效性
        /// </summary>
        /// <param name="row"></param>
        /// <param name="col"></param>
        /// <returns></returns>
        public bool Check(int row, int col)
        {
            if (row < 0)
            {
                LogError(string.Format("行号:{0},小于0", row));
                return false;
            }
            if (row >= rowMax)
            {
                LogError(string.Format("行号:{0},越界:{1}", row, rowMax));
                return false;
            }
            if (col < 0)
            {
                LogError(string.Format("列号:{0},小于0", col));
                return false;
            }
            if (col >= columnMax)
            {
                LogError(string.Format("列号:{0},越界:{1}", col, columnMax));
                return false;
            }
            return true;
        }

        /// <summary>
        /// 添加游戏对象
        /// </summary>
        /// <param name="go">游戏对象</param>
        public bool Add(GameObject go)
        {
            if (go == null) return false;
            Vector3 pos = go.transform.position;
            return Add(go, pos);
        }

        /// <summary>
        /// 添加游戏对象到指定位置的格子
        /// </summary>
        /// <param name="go">游戏对象</param>
        /// <param name="pos">位置</param>
        public bool Add(GameObject go, Vector3 pos)
        {
            if (go == null) return false;
            SceneGridNode node = Get(pos);
            if (node == null) return false;
            node.Add(go);
            return true;
        }

        /// <summary>
        /// 通过位置获取节点
        /// </summary>
        /// <param name="pos">位置</param>
        /// <returns></returns>
        public SceneGridNode Get(Vector3 pos)
        {
            if (nodeWidth <= 0) return null;
            if (nodeHeight <= 0) return null;
            if (!AreaTool.Contains(leftDownPoint, rightUpPoint, pos)) return null;
            int col = GetCol(leftDownPoint.x, pos.x);
            int row = GetRow(leftDownPoint.z, pos.z);
            return Get(row, col);
        }

        /// <summary>
        /// 通过索引获取节点
        /// </summary>
        /// <param name="row">行号</param>
        /// <param name="col">列号</param>
        /// <returns></returns>
        public SceneGridNode Get(int row, int col)
        {
            if (!Check(row, col)) return null;
            int id = row * RowMax + col;
            return Get(id);
        }

        /// <summary>
        /// 通过ID获取节点
        /// </summary>
        /// <param name="id">ID</param>
        /// <returns></returns>
        public SceneGridNode Get(int id)
        {
            if (nodeDic.ContainsKey(id)) return nodeDic[id];
            return null;
        }

        /// <summary>
        /// 判断是否包含指定ID的节点
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public bool Contains(int id)
        {
            return nodeDic.ContainsKey(id);
        }

        /// <summary>
        /// 激活/隐藏
        /// </summary>
        /// <param name="active"></param>
        public void SetActive(bool active)
        {
            int length = Nodes.Count;
            for (int i = 0; i < length; i++)
            {
                SceneGridNode node = nodes[i];
                node.SetActive(active);
            }
        }

        /// <summary>
        /// 输出错误信息
        /// </summary>
        /// <param name="err"></param>
        public void LogError(string err)
        {
            string msg = string.Format("{0},请通过快捷键Alt+S打开九宫格编辑器查看配置:{1},并确定是否打包", err, name);
            iTrace.Error("Loong", msg);
        }
        #endregion

        #region 编辑器
#if UNITY_EDITOR
        private int selectMenual = 0;

        private Color lineColor = new Color(0f, 1f, 0f, 0.2f);

        private void OnClickMenual()
        {
            if (selectMenual < 0) return;
            if (selectMenual >= menualInfos.Count) return;
            SceneViewUtil.Focus(menualInfos[selectMenual].pos);
        }

        private void LdPointChanged()
        {
            if (rightUpPoint.y != leftDownPoint.y) rightUpPoint.y = leftDownPoint.y;
        }

        private void RuPointChanged()
        {
            if (leftDownPoint.y != rightUpPoint.y) leftDownPoint.y = rightUpPoint.y;
        }


        /// <summary>
        /// 绘制基础属性
        /// </summary>
        public void DrawBasic()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.IntSlider("行数:", ref rowMax, 1, 200, this);
            UIEditLayout.IntSlider("列数:", ref columnMax, 1, 200, this);
            UIEditLayout.Vector3Field("左下角点:", ref leftDownPoint, this, LdPointChanged);
            UIEditLayout.Vector3Field("右上角点:", ref rightUpPoint, this, RuPointChanged);
            if (!EditorApplication.isPlaying) GUI.enabled = false;
            EditorGUILayout.FloatField("节点宽度(米):", nodeWidth);
            EditorGUILayout.FloatField("节点高度(米):", nodeHeight);
            if (!EditorApplication.isPlaying) GUI.enabled = true;
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制节点列表
        /// </summary>
        public void DrawNodes()
        {
            UIDrawTool.IDrawLst<GridNodeGbjInfo>(this, menualInfos, "MenualInfos", "手动游戏对象列表");
            //UIDrawTool.IDrawLst<SceneGridNode>(this, nodes, "Nodes", "节点列表");
        }

        /// <summary>
        /// 绘制网格
        /// </summary>
        /// <param name="view"></param>
        public void OnSceneGrid(SceneView view)
        {
            UIHandleTool.Begin();
            UIDrawTool.Buttons(this, "手动游戏对象", "游戏对象", menualInfos.Count, ref selectMenual, OnClickMenual);
            UIHandleTool.End();
            UIVectorUtil.DrawInfos<GridNodeGbjInfo>(this, menualInfos, Color.magenta, "游戏对象", ref selectMenual);

            lineColor.a = 0.3f;
            int rowIndex = rowMax - 1;
            int colIndex = columnMax - 1;
            UIHandleTool.Position(this, ref leftDownPoint, LdPointChanged);
            UIHandleTool.Position(this, ref rightUpPoint, RuPointChanged);
            Handles.Label(rightUpPoint, string.Format("右上角点:索引[{0},{1}]", rowIndex, colIndex));
            Handles.Label(leftDownPoint, "左下角点,索引:[0,0]");

            UIHandleTool.DrawGrid(leftDownPoint, rightUpPoint, rowMax, columnMax, lineColor);
        }

        /// <summary>
        /// 绘制节点
        /// </summary>
        /// <param name="view"></param>
        public void OnSceneNodes(SceneView view)
        {
            int length = nodes.Count;
            for (int i = 0; i < length; i++) nodes[i].OnSceneGUI(view);
        }

        public void EditUpdate()
        {
            SetWidthHeight();
        }
#endif
        #endregion
    }
}