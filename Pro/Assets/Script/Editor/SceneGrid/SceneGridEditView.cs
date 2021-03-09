using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格编辑视图
    /// </summary>
    public class SceneGridEditView : EditViewBase
    {
        #region 字段
        [SerializeField]
        private bool drawGrid = true;

        [SerializeField]
        private bool drawNode = true;

        [SerializeField]
        private SceneGrid asset = null;

        #endregion

        #region 属性

        /// <summary>
        /// 绘制网格
        /// </summary>
        public bool DrawGrid
        {
            get { return drawGrid; }
            set { drawGrid = value; }
        }

        /// <summary>
        /// 绘制节点
        /// </summary>
        public bool DrawNode
        {
            get { return drawNode; }
            set { drawNode = value; }
        }


        /// <summary>
        /// 九宫格资源
        /// </summary>
        public SceneGrid Asset
        {
            get { return asset; }
            set { asset = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public SceneGridEditView()
        {

        }
        #endregion

        #region 私有方法
        private bool Check()
        {
            if (Application.isPlaying)
            {
                ShowTip("运行中不允许此操作"); return false;
            }
            Transform root = SceneGridMgr.Root;
            if (root == null)
            {
                UIEditTip.Error("Loong,没有发现名称为:{0}的根结点", SceneGridMgr.RootName);
                return false;
            }
            return true;
        }

        /// <summary>
        /// 清理手动游戏对象
        /// </summary>
        private void ClearManual()
        {
            if (!EditorUtility.DisplayDialog("", "确定清除手动添加游戏对象？", "确定", "取消")) return;
            EditUtil.RegisterUndo("ClearManualPaths", Asset);
            Asset.MenualInfos.Clear();
            Win.ShowTip("已清理");
        }


        /// <summary>
        /// 定位
        /// </summary>
        private void Ping()
        {
            EditUtil.Ping(Asset);
        }

        /// <summary>
        /// 返回无对话框
        /// </summary>
        private void Return()
        {
            Win.Switch<SceneGridSelectView>();
        }

        /// <summary>
        /// 返回有对话框
        /// </summary>
        private void ReturnWithDialog()
        {
            if (EditorUtility.DisplayDialog("", "数据保存了吗?", "已保存", "取消"))
            {
                Return();
            }
            else
            {
                UIEditTip.Log("已取消");
            }
        }

        /// <summary>
        /// 手动添加路径
        /// </summary>
        private void AddManualPath(SceneView view)
        {
            if (Event.current.type == EventType.DragUpdated)
            {
                if (DragAndDrop.objectReferences.Length > 0)
                {
                    DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
                }
            }
            else if (Event.current.type == EventType.DragPerform)
            {
                Vector3 pos = SceneViewUtil.GetPos(view, Asset.LeftDownPoint.y);
                Vector3 ldPoint = Asset.LeftDownPoint;
                Vector3 ruPoint = Asset.RightUpPoint;
                if (!AreaTool.Contains(ldPoint, ruPoint, pos))
                {
                    view.ShowTip("在九宫格之外"); return;
                }
                EditUtil.RegisterUndo("AddManualPath", Asset);
                StringBuilder sb = new StringBuilder();
                int length = DragAndDrop.objectReferences.Length;
                for (int i = 0; i < length; i++)
                {
                    Object obj = DragAndDrop.objectReferences[i];
                    string assetPath = AssetDatabase.GetAssetPath(obj);
                    sb.Append(obj.name);
                    if (!string.IsNullOrEmpty(assetPath)) continue;
                    GameObject go = obj as GameObject;
                    if (go == null) continue;
                    if (go.transform.parent.name != SceneGridMgr.RootName)
                    {
                        sb.Append("不是根结点:");
                        sb.Append(SceneGridMgr.RootName).Append("的子物体");
                    }
                    else
                    {
                        sb.Append("添加到").Append(pos);
                        GridNodeGbjInfo info = new GridNodeGbjInfo();
                        info.Path = go.name; info.pos = pos.Precision();
                        Asset.MenualInfos.Add(info);
                    }
                    sb.AppendLine();
                }
                UIEditTip.Log(sb.ToString());
            }
        }

        private void DrawNullAsset()
        {
            if (Application.isPlaying)
            {
                Asset = SceneGridMgr.Current;
                if (Asset == null) UIEditLayout.HelpWaring("等待设置九宫格对象");
            }
            else
            {
                UIEditLayout.HelpWaring("没有设置九宫格对象");
            }
        }
        #endregion

        #region 保护方法

        protected override void OpenCustom()
        {
            Win.SetTitle("编辑视图");
        }

        protected override void CloseCustom()
        {
            Asset = null;
        }
        protected override void OnGUICustom()
        {
            if (Asset == null) { DrawNullAsset(); return; }
            if (e.type == EventType.ContextClick) ContextClick();
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("绘制网格:", ref drawGrid, this);
            UIEditLayout.Toggle("绘制节点:", ref drawNode, this);
            EditorGUILayout.EndVertical();
            if (EditorApplication.isPlaying) GUI.enabled = false;
            Asset.DrawBasic();
            Asset.DrawNodes();
            if (EditorApplication.isPlaying) GUI.enabled = true;
        }

        protected override void ClearUndo()
        {
            if (Asset != null) Undo.ClearUndo(Asset);
        }

        protected override void ContextClick()
        {
            if (Application.isPlaying) return;
            GenericMenu menu = new GenericMenu();
            menu.AddSeparator("");
            menu.AddItem("清理手动添加游戏对象", false, ClearManual);
            menu.AddSeparator("");
            menu.AddItem("返回", false, ReturnWithDialog);
            menu.AddSeparator("");
            menu.AddItem("定位", false, Ping);
            menu.ShowAsContext();
        }

        protected override void OnDestroyCustom()
        {
            Asset = null;
        }

        #endregion

        #region 公开方法

        public override void Update()
        {
            if (Application.isPlaying) return;
            Asset.EditUpdate();
        }

        public override void OnPlaymodeChanged(bool playing)
        {
            if (playing)
            {
                Asset = null;
            }
        }

        public override void OnSceneGUI(SceneView view)
        {
            if (asset == null) return;
            if (drawNode) asset.OnSceneNodes(view);
            if (drawGrid) asset.OnSceneGrid(view);
            if (EditorApplication.isPlaying) return;
            AddManualPath(view);
        }
        #endregion
    }
}