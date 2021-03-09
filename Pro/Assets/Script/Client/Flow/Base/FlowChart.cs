using System;
using Phantom;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Text;
using System.Diagnostics;
using System.Collections.Generic;
using iTrace = Loong.Game.iTrace;
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
    /// 流程树基类
    /// </summary>
    public class FlowChart
    {
        #region 字段
        private ushort times;

        private bool running = false;

        private Transform root = null;

        /// <summary>
        /// 结束事件
        /// </summary>
        public Action<bool> endHandler = null;

        /// <summary>
        /// 流程节点字典
        /// </summary>
        private Dictionary<string, FlowChartNode> nodeDic = new Dictionary<string, FlowChartNode>();

        /// <summary>
        /// 流程数所有节点
        /// </summary>
        protected List<FlowChartNode> allNodes = new List<FlowChartNode>();

        /// <summary>
        /// 流程树所有连线
        /// </summary>
        protected List<FlowChartLink> allLinks = new List<FlowChartLink>();

        protected FlowChartNode startNode;

        public string startName = null;


        public string name = null;
        #endregion

        #region 属性

        /// <summary>
        /// 运行次数
        /// </summary>
        public ushort Times
        {
            get { return times; }
            set { times = value; }
        }


        /// <summary>
        /// 判断是否运行
        /// </summary>
        public bool Running
        {
            get { return running; }
            protected set { running = value; }
        }

        public Transform Root
        {
            get
            {
                if (root == null) CreateRoot();
                return root;
            }
        }

        /// <summary>
        /// 起点
        /// </summary>
        public FlowChartNode StartNode
        {
            get { return startNode; }
        }

        /// <summary>
        /// 所有节点
        /// </summary>
        public List<FlowChartNode> Nodes
        {
            get { return allNodes; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 启动回调 需要自己注册注销 参数为流程树名称
        /// </summary>
        public static event Action<string> start;

        #endregion

        #region 私有方法

        private void InitNodes()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                var node = allNodes[i];
                if (node == null)
                {
                    iTrace.Error("node is null:  ", node.name);
                }
                else
                {
                    node.flowChart = this;
                    node.Initialize();
                }
            }
        }

        /// <summary>
        /// 初始化线
        /// </summary>
        private void InitLinks()
        {
            var length = allLinks.Count;
            for (int i = 0; i < length; i++)
            {
                var line = allLinks[i];
                var begNode = Get(line.bName);
                line.start = begNode;
                var endNode = Get(line.eName);
                line.end = endNode;
            }
        }

        private void CreateRoot()
        {
            GameObject go = null;
            go = GameObject.Find(name);
            if (go == null)
            {
                go = new GameObject(name);
            }
            go.hideFlags = HideFlags.DontSave;
            var root = go.transform;
            this.root = root;
        }

        public void Update()
        {
            if (!Running) return;
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].Execute();
            }
#if UNITY_EDITOR
            EditDynamicInspector();
#endif
        }

        #endregion

        #region 保护方法

        /// <summary>
        /// 设置流程树字典
        /// </summary>
        protected void SetNodeDic()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                var node = allNodes[i];
                string key = node.name;
                if (nodeDic.ContainsKey(key))
                {
                    iTrace.Error("Loong", "set flowchart:{0} dic,have repeat name:{1}", name, key);
                }
                else
                {
                    nodeDic.Add(key, node);
                }
            }
        }


        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void Initialize()
        {
            SetNodeDic();
            InitLinks();
            InitNodes();
            startNode = Get(startName);
            Check();
        }


        #endregion

        #region 公开方法
        public void ReadFromJson(string path)
        {
            if (File.Exists(path))
            {
                var str = FileTool.Load(path);
                Read(str);
            }
        }

        public void Read(string str)
        {
            var fi = JsonUtility.FromJson<FTInfo>(str);
            var infos = fi.infos;
            name = fi.name;
            startName = fi.startName;
            int length = infos.Count;

            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                var type = Type.GetType(info.type);
                if (type == null)
                {
                    iTrace.Error("Loong", "no type:{0}", info.type);
                }
                else
                {
                    var o = JsonUtility.FromJson(info.data, type);
                    var node = o as FlowChartNode;
                    allNodes.Add(node);
                }
            }
            allLinks = fi.links;
        }


        /*public void Save(string path)
        {
            var fi = new FTInfo();
            int nodeLen = allNodes.Count;
            for (int i = 0; i < nodeLen; i++)
            {
                var node = allNodes[i];
                var fni = new FTNInfo();
                fni.type = node.GetType().FullName;
                fni.data = JsonUtility.ToJson(node, false);
                fi.infos.Add(fni);
            }
            fi.name = name;
            fi.startName = startName;
            fi.links = allLinks;
            JsonUtil.Save<FTInfo>(path, fi, false);
        }*/

        public void ReadFromFile(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open))
            {
                Read(fs);
            }
        }

        public void Read(TextAsset asset)
        {
            using (var ms = new MemoryStream(asset.bytes))
            {
                Read(ms);
            }
        }

        public void Read(Stream stream)
        {
            try
            {
                using (var br = new BinaryReader(stream, Encoding.UTF8))
                {
                    ExString.Read(ref name, br);
#if UNITY_EDITOR

                    if (stream is FileStream)
                    {
                        var fs = stream as FileStream;
                        var fn = Path.GetFileNameWithoutExtension(fs.Name);
                        name = fn;
                    }
#endif
                    ExString.Read(ref startName, br);
                    //name = br.ReadString();
                    //startName = br.ReadString();
                    int length = br.ReadInt32();
                    for (int i = 0; i < length; i++)
                    {
                        var it = new FlowChartLink();
                        it.Read(br);
                        allLinks.Add(it);
                    }

                    length = br.ReadInt32();
                    for (int i = 0; i < length; i++)
                    {
                        var typeStr = "";
                        ExString.Read(ref typeStr, br);
                        var type = Type.GetType(typeStr);
                        var obj = Activator.CreateInstance(type);
                        var node = obj as FlowChartNode;
                        node.Read(br);
                        allNodes.Add(node);
                    }
                }
            }
            catch (Exception e)
            {

                iTrace.Error("Loong", "read:{0}, err:{1}", name, e.Message);
            }
        }


        public void Save(string path)
        {
            using (var fs = new FileStream(path, FileMode.Create))
            {
                using (var bw = new BinaryWriter(fs, Encoding.UTF8))
                {
                    ExString.Write(name, bw);
                    ExString.Write(startName, bw);
                    //bw.Write(name);
                    //bw.Write(startName);
                    int length = allLinks.Count;
                    bw.Write(length);
                    for (int i = 0; i < length; i++)
                    {
                        allLinks[i].Write(bw);
                    }

                    length = allNodes.Count;
                    bw.Write(length);
                    for (int i = 0; i < length; i++)
                    {
                        allNodes[i].Write(bw);
                    }
                }
            }
        }



        public FlowChartNode Get(string name)
        {
            if (string.IsNullOrEmpty(name))
            {
                return null;
            }
            if (nodeDic.ContainsKey(name))
            {
                return nodeDic[name];
            }
            return null;
        }

        public T Get<T>(string name) where T : FlowChartNode
        {
            var node = Get(name);
            T t = node as T;
            return t;
        }


        public List<T> FindNodes<T>() where T : FlowChartNode
        {
            List<T> lst = null;
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                if (allNodes[i] is T)
                {
                    if (lst == null) lst = new List<T>();
                    lst.Add(allNodes[i] as T);
                }
            }
            return lst;
        }

        public FlowChartLink FindLink(FlowChartNode start, FlowChartNode end)
        {
            int length = allLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = allLinks[i];
                if (link.start == start && link.end == end)
                {
                    return link;
                }
            }
            return null;
        }

        public List<FlowChartLink> FindLinkByStartNode(FlowChartNode node)
        {
            List<FlowChartLink> lst = new List<FlowChartLink>();
            int length = allLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = allLinks[i];
                if (link.start == node)
                {
                    lst.Add(link);
                }
            }
            return lst;
        }

        public List<FlowChartLink> FindLinkByEndNode(FlowChartNode node)
        {
            List<FlowChartLink> lst = new List<FlowChartLink>();
            int length = allLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = allLinks[i];
                if (link.end == node)
                {
                    lst.Add(link);
                }
            }
            return lst;
        }

        /// <summary>
        /// 预加载
        /// </summary>
        public void Preload()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].Preload();
            }
        }

        /// <summary>
        /// 由开始节点启动流程
        /// </summary>
        public void StartUp()
        {
            if (Running) return;
            ++Times; Running = true;
            FlowChartMgr.Current = this;
            if (start != null)
            {
                start(name);
            }
            EventMgr.Trigger(EventKey.FlowChartStart);
            if (startNode != null) startNode.StartProcess();
            iTrace.Log("Loong", "FlowTree:{0}, startUp", name);
        }

        /// <summary>
        /// 指定节点启动流程
        /// </summary>
        /// <param name="nodeName"></param>
        public void StartUp(string nodeName)
        {
            if (Running) return;
            ++Times; Running = true;
            if (start != null)
            {
                EventMgr.Trigger(EventKey.FlowChartStart);
                start(name);
            }
            var node = Get(nodeName);
            if (node == null)
            {
                iTrace.Error("Loong", "no node:{0}, can't startup", nodeName);
            }
            else
            {
                node.SetInputNode(TransitionState.Complete);
                node.StartProcess();
                //UITip.eLog(string.Format("流程树:{0},从节点:{1} 启动", gameObject.name, nodeName));
            }
        }

        /// <summary>
        /// 重置关卡流程
        /// </summary>
        public void Reset()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].Reset();
            }
        }

        /// <summary>
        /// 停止关卡流程
        /// </summary>
        public void Stop()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].Stop();
            }
            Running = false;
            UIMgr.SetCamActive(true);
        }

        /// <summary>
        /// 释放指定类型的所有节点
        /// </summary>
        /// <param name="typeName">类型名称</param>
        public void ClearType(string typeName)
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                var node = allNodes[i];
                string nodeType = node.GetType().Name;
                if (nodeType == typeName)
                {
                    node.Dispose();
                }
            }
        }


        /// <summary>
        /// 释放关卡流程
        /// </summary>
        public virtual void Dispose()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].Dispose();
            }
            iTool.Destroy(Root.gameObject);
            UIMgr.SetCamActive(true);
        }


        /// <summary>
        /// 检查流程树
        /// </summary>
        public void Check()
        {
            if (startNode == null)
            {
                iTrace.Error("Loong", "flow tree:{0},no start node", name);
            }
        }

        /// <summary>
        /// 设置运行状态
        /// </summary>
        public void SetRunning()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode node = allNodes[i];
                if (node.Transition == TransitionState.Stop) continue;
                if (node.Transition == TransitionState.Complete) continue;
                return;
            }
            Running = false;
        }

        #region 事件

        /// <summary>
        /// 执行结束事件 true:胜利,false:失败
        /// </summary>
        public void ExecuteEndHandler(bool end)
        {
            if (endHandler != null) endHandler(end);
        }
        #endregion

        #endregion

        #region 编辑器/字段/属性/方法
#if UNITY_EDITOR
        private enum EditFlag
        {
            None,
            Create,
            Drag,
            Link,
            Rect,
        }

        #region 字段
        private Event e;
        private EditorWindow win;
        private EditFlag editFlag;
        private bool outputConnect;
        private Vector2 vectorStart;
        private FlowChartNode conectNode;
        private Rect rectArea = new Rect(0, 0, 0, 0);
        private Dictionary<string, FlowChartNode> dynamicNodes = new Dictionary<string, FlowChartNode>();

        protected List<FlowChartNode> selectNodes = new List<FlowChartNode>();
        protected List<FlowChartLink> selectLinks = new List<FlowChartLink>();
        #endregion

        #region 属性
        public FlowChartNode DragNode { get; set; }
        #endregion

        #region 私有方法


        /// <summary>
        /// 获取节点的不重复名称
        /// </summary>
        private string EditGetUniqueName<T>() where T : FlowChartNode
        {
            return EditGetUniqueName(typeof(T));
        }

        private string EditGetUniqueName(Type t)
        {
            var tn = t.Name;
            int idx = 0;
            while (true)
            {
                var name = tn + idx.ToString();
                if (EditCheckUnique(name)) return name;
                idx++;
            }
        }

        /// <summary>
        /// 添加一个选择节点
        /// </summary>
        private void EditAddSelectNodes(FlowChartNode node)
        {
            node.editSelect = true;
            selectNodes.Add(node);
            e.Use();
        }

        /// <summary>
        /// 移除一个选择节点
        /// </summary>
        private void EditRemoveSelectNodes(FlowChartNode node)
        {
            if (!selectNodes.Contains(node)) return;
            node.editSelect = false;
            selectNodes.Remove(node);
            e.Use();
        }

        /// <summary>
        /// 鼠标操作事件
        /// </summary>
        private void EditMouseEvent(Object o)
        {
            if (e.type == EventType.MouseDown)
            {
                if (e.button == 0) EditLefMouseDown();
                else if (e.button == 1) EditRigMouseDown();
            }
            else if (e.type == EventType.MouseDrag)
            {
                if (e.button == 0) EditLefMouseDrag();
                else if (e.button == 2) EditMidMouseDrag();
            }
            else if (e.type == EventType.MouseUp)
            {
                if (e.button == 0) EditLefMouseUp(o);
                else if (e.button == 2) EditMidMouseUp(o);
                editFlag = EditFlag.None;
                GUI.FocusControl("");
            }
            else if (e.type == EventType.KeyDown)
            {
                if (Application.isPlaying) return;
                if (e.keyCode == KeyCode.Delete) EditDelete(o);
                if (e.shift) if (e.Equals(Event.KeyboardEvent("#D"))) EditCopyNode(o);
            }
        }

        /// <summary>
        /// 鼠标左键按下事件
        /// </summary>
        private void EditLefMouseDown()
        {
            FlowChartNode inputNode = EditGetInputNode();
            if (inputNode != null)
            { EditLinkBeg(inputNode, false); return; }
            FlowChartNode outputNode = EditGetOutputNode();
            if (outputNode != null)
            { EditLinkBeg(outputNode, true); return; }
            DragNode = EditGetEnterNode();
            if (DragNode != null)
            {
                if (selectNodes.Contains(DragNode))
                { e.Use(); return; }
                EditClearSelectNodes();
                EditClearSelectLinks();
                EditSelectNode(DragNode);
                e.Use();
            }
            else
            {
                editFlag = EditFlag.Rect;
                vectorStart = e.mousePosition;
            }
        }

        /// <summary>
        /// 鼠标右键按下事件
        /// </summary>
        private void EditRigMouseDown()
        {
            DragNode = EditGetEnterNode();
            if (DragNode != null) EditSelectNode(DragNode);
            e.Use();
        }

        /// <summary>
        /// 鼠标左键拖动事件
        /// </summary>
        private void EditLefMouseDrag()
        {
            if (editFlag == EditFlag.Link) return;
            if (DragNode == null) return;
            if (editFlag == EditFlag.Create) EditDragCreateNode();
            else EditMouseDragNodes(selectNodes);
        }

        /// <summary>
        /// 鼠标中键拖动事件
        /// </summary>
        private void EditMidMouseDrag()
        {
            EditMouseDragNodes(allNodes);
        }

        /// <summary>
        /// 组合重构拖动事件
        /// </summary>
        private void EditMouseDragNodes(List<FlowChartNode> lst)
        {
            if (editFlag != EditFlag.Drag)
            { editFlag = EditFlag.Drag; EditRecordDragBeg(lst); }
            EditDragNodes(lst);
        }

        /// <summary>
        /// 鼠标左键弹起事件
        /// </summary>
        private void EditLefMouseUp(Object o)
        {
            if (editFlag == EditFlag.Drag) EditRecordDragEnd(selectNodes, o);
            else if (editFlag == EditFlag.Rect) EditRectangle();
            else if (editFlag == EditFlag.Link) EditLinkEnd(o);
        }

        /// <summary>
        /// 鼠标中键弹起事件
        /// </summary>
        private void EditMidMouseUp(Object o)
        {
            if (editFlag == EditFlag.Drag) EditRecordDragEnd(allNodes, o);
        }

        /// <summary>
        /// 绘制一些无法以事件为前提的flag
        /// </summary>
        private void EditDrawFlag()
        {
            if (editFlag == EditFlag.Rect)
            {
                EditRectArea();
                GUI.Box(rectArea, "", "SelectionRect");
                EditRepaint();

            }
            else if (editFlag == EditFlag.Link)
            {
                Vector2 end = outputConnect ? conectNode.EditOutputCenter() : conectNode.EditInputCenter();
                Vector2 beg = e.mousePosition;
                EditDrawLink(beg, end, false);
                EditRepaint();
            }
        }

        /// <summary>
        /// 通过区域获取一个点
        /// </summary>
        private FlowChartNode EditGetEnterNode()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode node = allNodes[i];
                if (!node.EditAreaContains(e.mousePosition)) continue;
                node.EditClickNode(); return node;
            }
            return null;
        }

        /// <summary>
        /// 通过输入区域获取一个点
        /// </summary>
        private FlowChartNode EditGetInputNode()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                if (allNodes[i].EditInputAreaContains(e.mousePosition))
                { return allNodes[i]; }
            }
            return null;
        }

        /// <summary>
        /// 通过输出区域获取一个点
        /// </summary>
        private FlowChartNode EditGetOutputNode()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                if (allNodes[i].EditOutputAreaContains(e.mousePosition))
                { return allNodes[i]; }
            }
            return null;
        }


        /// <summary>
        /// 连线结束
        /// </summary>
        private void EditLinkEnd(Object o)
        {
            Vector2 pos = e.mousePosition;
            Rect touchArea = new Rect(pos.x - 5 * 0.5f, pos.y - 5 * 0.5f, 5, 5);
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode beg = allNodes[i];
                if (conectNode == beg) continue;
                if (EditLinkEnd(beg, conectNode, touchArea, outputConnect, o))
                { win.ShowNotification(new GUIContent("连线成功")); return; }
            }
            win.ShowNotification(new GUIContent("连线失败"));
        }

        /// <summary>
        /// 添加线是否成功
        /// </summary>
        private bool EditLinkEnd(FlowChartNode beg, FlowChartNode end, Rect area, bool output, Object o)
        {
            if (output) { if (!beg.EditHitInputArea(area)) return false; }
            else { if (!beg.EditHitOutputArea(area)) return false; }
            if (FindLink(beg, end) != null) return false;
            FlowChartLink link = new FlowChartLink();
            if (output) { link.start = end; link.end = beg; }
            else { link.start = beg; link.end = end; }
            EditUtil.RegisterUndo("AddLink", o);
            allLinks.Add(link);
            e.Use();
            return true;
        }

        /// <summary>
        /// 矩形区域选择点
        /// </summary>
        private void EditRectangle()
        {
            EditClearSelectNodes();
            EditClearSelectLinks();
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode node = allNodes[i];
                if (node.EditHitNodeArea(rectArea)) EditSelectNode(node);
            }
        }

        /// <summary>
        /// 拖动点的位置
        /// </summary>
        private void EditDragNodes(List<FlowChartNode> lst)
        {
            int length = lst.Count;
            if (lst.Count == 0) return;
            for (int i = 0; i < length; i++)
            {
                lst[i].pos += e.delta;
            }
            e.Use();
        }

        /// <summary>
        /// 拖动创建的节点
        /// </summary>
        private void EditDragCreateNode()
        {
            DragNode.pos = e.mousePosition - DragNode.editSize * 0.5f;
            DragNode.pos.x = (DragNode.pos.x < 0) ? 0 : DragNode.pos.x;
            e.Use();
        }

        /// <summary>
        /// 删除操作
        /// </summary>
        private void EditDelete(Object o)
        {

            Undo.RegisterCompleteObjectUndo(new UnityEngine.Object[] { o }, "Delete");
            while (true)
            {
                if (selectNodes.Count == 0) break;
                EditDeleteNode(selectNodes[0], o);
                selectNodes.RemoveAt(0);
            }
            while (true)
            {
                if (selectLinks.Count == 0) break;
                EditDeleteLink(selectLinks[0]);
                selectLinks.RemoveAt(0);
            }
            e.Use();
            AssetDatabase.SaveAssets();
        }

        /// <summary>
        /// 绘制矩形选择区域
        /// </summary>
        private void EditRectArea()
        {
            rectArea.x = (vectorStart.x > e.mousePosition.x) ? e.mousePosition.x : vectorStart.x;
            rectArea.y = (vectorStart.y > e.mousePosition.y) ? e.mousePosition.y : vectorStart.y;
            rectArea.width = e.mousePosition.x - vectorStart.x;
            rectArea.width = (rectArea.width > 0) ? rectArea.width : -rectArea.width;
            rectArea.height = e.mousePosition.y - vectorStart.y;
            rectArea.height = (rectArea.height > 0) ? rectArea.height : -rectArea.height;
        }

        /// <summary>
        /// 绘制连线
        /// </summary>
        private bool EditDrawLink(Vector2 beg, Vector2 end, bool select)
        {
            Vector2 begTan = new Vector2(beg.x, (beg.y + end.y) * 0.5f);
            Vector2 endTan = new Vector2(end.x, (beg.y + end.y) * 0.5f);
            Handles.BeginGUI();
            Handles.DrawBezier(beg, end, begTan, endTan, select ? Color.white : Color.gray, null, select ? 4 : 2);
            Handles.EndGUI();
            if (HandleUtility.DistancePointBezier(e.mousePosition, beg, end, begTan, endTan) < 5) return true;
            return false;

        }

        /// <summary>
        /// 绘制所有的点
        /// </summary>
        private void EditDrawNodes()
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode node = allNodes[i];
                if (node == null) continue;
                node.EditDrawNode(e);
            }
        }

        /// <summary>
        /// 记录移动前点的位置
        /// </summary>
        private void EditRecordDragBeg(List<FlowChartNode> lst)
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                lst[i].EditRecordDragBeg();
            }
        }

        /// <summary>
        /// 记录移动后点的位置
        /// </summary>
        private void EditRecordDragEnd(List<FlowChartNode> lst, Object o)
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                lst[i].EditRecordUndoDrag(o);
            }
        }

        /// <summary>
        /// 绘制所有的线
        /// </summary>
        private void EditDrawLinks()
        {
            for (int i = 0; i < allLinks.Count; i++)
            {
                FlowChartLink link = allLinks[i];
                Vector3 beg = link.start.EditOutputCenter();
                Vector3 end = link.end.EditInputCenter();
                beg.y += 6; end.y -= 6;
                if (!EditDrawLink(beg, end, link.editSelect)) continue;
                if (editFlag != EditFlag.None) continue;
                if (e.type != EventType.MouseDown) continue;
                EditSelectLink(link);
            }
        }

        private void EditDynamicInspector()
        {
            if (Input.GetKey(KeyCode.LeftAlt) || Input.GetKeyDown(KeyCode.RightAlt))
            {
                if (Input.GetKeyDown(KeyCode.DownArrow))
                {
                    EditCompleteDynamic();
                }
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 设置起点
        /// </summary>
        /// <returns></returns>
        public void EditSetStartNode(Object o)
        {
            if (DragNode == null)
            { win.ShowNotification(new GUIContent("没有选中点")); return; }
            EditUtil.RegisterUndo("SetStart", o);
            if (startNode != null)
            {
                if (DragNode.name.Equals(startNode.name))
                {
                    win.ShowNotification(new GUIContent(string.Format("{0}已经是起点", startNode.name)));
                    return;
                }
                else
                {
                    startNode.EditSetStartStyle(false, o);
                    List<FlowChartLink> links = FindLinkByEndNode(DragNode);
                    int length = links.Count;
                    for (int i = 0; i < length; i++)
                    {
                        FlowChartLink link = links[i];
                        allLinks.Remove(link);
                        selectLinks.Remove(link);
                    }
                }
            }
            startNode = DragNode;
            startName = DragNode.name;
            startNode.EditSetStartStyle(true, o);
            win.ShowNotification(new GUIContent(string.Format("设置{0}为起点成功", startNode.name)));
            e.Use();
        }

        /// <summary>
        /// 检查是否是起点
        /// </summary>
        public bool EditCheckStartNode(FlowChartNode node)
        {
            return object.ReferenceEquals(node, startNode);
        }

        /// <summary>
        /// 检查起点是否存在 返回true存在
        /// </summary>
        /// <returns></returns>
        public bool EditExistStartNode()
        {
            return startNode != null;
        }

        /// <summary>
        /// 添加选择点
        /// </summary>
        /// <param name="node"></param>
        public void EditSelectNode(FlowChartNode node)
        {
            if (selectNodes.Contains(node)) return;
            selectLinks.Clear();
            EditAddSelectNodes(node);
        }

        /// <summary>
        /// 清理选择点
        /// </summary>
        public void EditClearSelectNodes()
        {
            int length = selectNodes.Count;
            if (length == 0) return;
            for (int i = 0; i < length; i++)
            {
                selectNodes[i].editSelect = false;
            }
            selectNodes.Clear();
            e.Use();
        }

        /// <summary>
        /// 添加选择线
        /// </summary>
        public void EditSelectLink(FlowChartLink link)
        {
            EditClearSelectNodes();
            EditClearSelectLinks();
            if (selectLinks.Contains(link)) return;
            selectLinks.Add(link);
            link.editSelect = true;
            e.Use();
        }

        /// <summary>
        /// 清理选择线
        /// </summary>
        public void EditClearSelectLinks()
        {
            int length = selectLinks.Count;
            if (length == 0) return;
            for (int i = 0; i < length; i++)
            {
                selectLinks[i].editSelect = false;
            }
            selectLinks.Clear();
            e.Use();
        }


        /// <summary>
        /// 删除点
        /// </summary>
        public void EditDeleteNode(FlowChartNode node, Object o)
        {
            allNodes.Remove(node);
            allLinks.RemoveAll(delegate (FlowChartLink link)
            {
                if (link.start == node || link.end == node) return true;
                return false;
            });
            EditUtil.RegisterUndo("Delete", o);
            node.Dispose();
            e.Use();
        }

        /// <summary>
        /// 删除线
        /// </summary>
        public void EditDeleteLink(FlowChartLink link)
        {
            allLinks.Remove(link);
            e.Use();
        }

        /// <summary>
        /// 绘制流程树
        /// </summary>
        public void EditDrawTree(Event ev, Object o)
        {
            e = ev;
            EditDrawLinks();
            EditDrawNodes();
            EditMouseEvent(o);
            EditDrawFlag();
        }

        /// <summary>
        /// 设置窗口
        /// </summary>
        public void EditSetWindow(EditorWindow win)
        {
            this.win = win;
        }

        /// <summary>
        /// 重绘窗口
        /// </summary>
        public void EditRepaint()
        {
            if (win != null) win.Repaint();
        }

        /// <summary>
        /// 创建节点
        /// </summary>
        public void EditCreateNode<T>(Object o, Vector2 bornPos) where T : FlowChartNode, new()
        {
            editFlag = EditFlag.Create;
            var name = EditGetUniqueName<T>();
            T t = new T();
            t.name = name;
            allNodes.Add(t);
            t.pos = bornPos;
            t.flowChart = this;
            t.EditCreate();
            t.EditInitialize();
            t.EditRefresh();
            DragNode = t;
            if (startNode == null) EditSetStartNode(o);
            EditClearSelectLinks();
            EditClearSelectNodes();
            EditAddSelectNodes(t);
        }

        /// <summary>
        /// 复制节点
        /// </summary>

        public void EditCopyNode(Object o)
        {
            if (DragNode == null)
            {
                win.ShowNotification(new GUIContent("没有选定任何节点,无法复制"));
            }
            else
            {
                var type = DragNode.GetType();
                var obj = Activator.CreateInstance(type);
                var node = obj as FlowChartNode;
                var name = EditGetUniqueName(type);
                node.name = name;
                allNodes.Add(node);
                nodeDic.Add(name, node);
                node.flowChart = this;
                node.EditInitialize();
                node.EditCopy(DragNode);
                EditClearSelectNodes();
                EditAddSelectNodes(node);
                node.pos = DragNode.pos + DragNode.editSize;
                DragNode = node;
                var tip = string.Format("复制新的节点:{0}成功", node.name);
                win.ShowNotification(new GUIContent(tip));
                e.Use();
            }
        }

        /// <summary>
        /// 开始连线
        /// </summary>
        /// <param name="node"></param>
        /// <param name="output"></param>
        /// <returns></returns>
        public bool EditLinkBeg(FlowChartNode node, bool output)
        {
            if (Application.isPlaying) return false;
            if (editFlag != EditFlag.None) return false;
            editFlag = EditFlag.Link;
            outputConnect = output;
            conectNode = node;
            e.Use();
            return true;
        }

        /// <summary>
        /// 检查名称是否已经存在
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public bool EditCheckUnique(string name)
        {
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                if (allNodes[i].name.Equals(name)) return false;
            }
            return true;
        }

        /// <summary>
        /// 移动选择点列表
        /// </summary>
        public void Ed_MoveNodes()
        {
            EditDragNodes(selectNodes);
        }

        /// <summary>
        /// 判断选择的点是否包含一个点
        /// </summary>
        public bool EditSelectContains(FlowChartNode node)
        {
            return selectNodes.Contains(node);
        }

        /// <summary>
        /// 绘制选择点的属性
        /// </summary>
        public void EditDrawProperty(Object o)
        {
            if (selectNodes.Count > 0)
            {
                if (selectNodes[0] != null) { selectNodes[0].EditDrawProperty(o); }
            }
            else
            {
                EditorGUILayout.HelpBox("没有任何节点被选择", MessageType.Info);
            }
        }

        /// <summary>
        /// 绘制场景视图
        /// </summary>
        public void EditDrawSceneGUI(Object o)
        {
            int length = selectNodes.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartNode node = selectNodes[i];
                if (node == null) continue;
                node.EditHitSceneView(o);
                node.EditDrawSceneGui(o);
            }
        }

        /// <summary>
        /// 清除撤销
        /// </summary>
        public void EditClearUndo(Object o)
        {
            Undo.ClearUndo(o);
            int length = allNodes.Count;
            for (int i = 0; i < length; i++)
            {
                allNodes[i].EditClearUndo(o);
            }
        }

        public void EditTestContext()
        {
            if (e == null) return;
            if (e.type == EventType.Repaint) return;
            EditorGUILayout.BeginVertical();
            EditorGUILayout.LabelField("事件:" + e.type);
            EditorGUILayout.LabelField("状态:" + editFlag);
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制监视面板
        /// </summary>
        public void EditDrawInspectorGUI(Object o)
        {
            if (startNode != null) EditorGUILayout.TextField("起点", startNode.name);
            //UIDrawTool.ObjectLst<FlowChartNode>(o, allNodes, "AllNodes", "所有流程点列表:");
            UIDrawTool.IDrawLst<FlowChartLink>(o, allLinks, "AllLinks", "所有流程线列表");
        }

        /// <summary>
        /// 编辑器初始化
        /// </summary>
        public void EditInitialize(Object o)
        {
            SetNodeDic();
            InitLinks();
            startNode = Get(startName);
            int nodeLen = allNodes.Count;
            for (int i = 0; i < nodeLen; i++)
            {
                var node = allNodes[i];
                node.flowChart = this;
                node.EditInitialize();
            }
            if (startNode != null)
            {
                startNode.EditSetStartStyle(true, o);
            }
        }

        /// <summary>
        /// 添加动态节点
        /// </summary>
        public void EditAddDynamic(FlowChartNode node)
        {
            if (node == null) return;
            string key = node.name;
            if (dynamicNodes.ContainsKey(key)) return;
            dynamicNodes.Add(key, node);
        }

        /// <summary>
        /// 移除动态节点
        /// </summary>
        public void EditRemoveDynamic(string key)
        {
            if (dynamicNodes.ContainsKey(key)) dynamicNodes.Remove(key);
        }

        /// <summary>
        /// 停止动态节点
        /// </summary>
        public void EditCompleteDynamic()
        {
            if (!Running) return;
            if (dynamicNodes.Count == 0) return;
            StringBuilder sb = new StringBuilder();
            sb.Append("快速跳过节点:\n");
            Dictionary<string, FlowChartNode> temp = new Dictionary<string, FlowChartNode>(dynamicNodes);
            foreach (KeyValuePair<string, FlowChartNode> item in temp)
            {
                sb.Append(item.Value.name).Append("\n");
                item.Value.EditCompleteDynamic();
            }
            UIEditTip.Log(sb.ToString());
        }

        /// <summary>
        /// 设置标签
        /// </summary>
        /// <param name="flags"></param>
        public void EditSetFlags(HideFlags flags)
        {
            root.gameObject.hideFlags = flags;
        }

        #endregion
#endif
        #endregion
    }
}