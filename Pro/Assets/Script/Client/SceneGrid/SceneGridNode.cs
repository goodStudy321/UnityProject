using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格节点
    /// </summary>
    [Serializable]
    public class SceneGridNode : IDisposable
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        [SerializeField]
        private int row = -1;

        [SerializeField]
        private int column = -1;

        [SerializeField]
        private SceneGrid grid = null;

        private List<int> ids = new List<int>();

        private List<GameObject> gos = null;

        [SerializeField]
        private Vector3 rightUpPoint = new Vector3(40, 0, 40);

        [SerializeField]
        private Vector3 leftDownPoint = new Vector3(-40, 0, -40);

        #endregion

        #region 属性
        /// <summary>
        /// 行索引*行数+列索引
        /// </summary>
        public int ID
        {
            get { return Row * Grid.RowMax + Column; }
        }


        /// <summary>
        /// 所在九宫格ID列表
        /// </summary>
        public List<int> IDS
        {
            get { return ids; }
            set { ids = value; }
        }

        /// <summary>
        /// 行
        /// </summary>
        public int Row
        {
            get { return row; }
            set { row = value; }
        }

        /// <summary>
        /// 列
        /// </summary>
        public int Column
        {
            get { return column; }
            set { column = value; }
        }

        /// <summary>
        /// 九宫格
        /// </summary>
        public SceneGrid Grid
        {
            get { return grid; }
            set { grid = value; }
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

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public SceneGridNode()
        {

        }
        #endregion

        #region 私有方法


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public void Init()
        {
            SetIDS();
        }

        /// <summary>
        /// 向游戏对象列表中添加项
        /// </summary>
        /// <param name="go">游戏对象</param>
        public void Add(GameObject go)
        {
            if (go == null) return;
            if (gos == null) gos = new List<GameObject>();
            gos.Add(go);
        }

        /// <summary>
        /// 设置ID列表
        /// </summary>
        public void SetIDS()
        {
            ids.Clear();
            int range = Grid.Range;
            int maxRow = Grid.RowMax - 1;
            int maxCol = Grid.ColumnMax - 1;

            int begRow = Row - range;
            if (begRow < 1) begRow = 0;
            int begCol = Column - range;
            if (begCol < 1) begCol = 0;

            int endRow = Row + range;
            if (endRow > maxRow) endRow = maxRow;
            endRow += 1;

            int endCol = Column + range;
            if (endCol > maxCol) endCol = maxCol;
            endCol += 1;
            for (int r = begRow; r < endRow; r++)
            {
                for (int c = begCol; c < endCol; c++)
                {
                    int nodeID = r * Grid.RowMax + c;
                    ids.Add(nodeID);
                    if (Grid.Contains(nodeID)) continue;
                    Grid.LogError(string.Format("没有发现索引为:[{0},{1}],ID为:{2}的节点", begRow, begCol, nodeID));
                }
            }
        }

        /// <summary>
        /// 释放
        /// </summary>
        public void Dispose()
        {
            Row = -1;
            Column = -1;
            if (gos != null) gos.Clear();
        }

        /// <summary>
        /// 激活/隐藏此节点内所有游戏对象
        /// </summary>
        /// <param name="active"></param>
        public void SetActive(bool active)
        {
            if (gos == null) return;
            int length = gos.Count;
            for (int i = 0; i < length; i++)
            {
                GameObject go = gos[i];
                if (go == null) continue;
                go.SetActive(active);
            }
        }

        /// <summary>
        /// 激活/隐藏此节点与另外一个节点不重合的部分
        /// </summary>
        /// <param name="other"></param>
        public void SetGridActive(SceneGridNode other, bool active)
        {
            if (other == null) return;
            int length = ids.Count;
            for (int i = 0; i < length; i++)
            {
                int nodeID = ids[i];
                if (other.IDS.Contains(nodeID)) continue;
                SceneGridNode node = Grid.Get(nodeID);
                if (node == null)
                {
                    Grid.LogError(string.Format("没有发现ID为:{0}的节点", nodeID));
                }
                else
                {
                    node.SetActive(active);
                }
            }
        }
        /// <summary>
        /// 激活/隐藏周围九个节点
        /// </summary>
        /// <param name="active"></param>
        public void SetGridActive(bool active)
        {
            int length = IDS.Count;
            for (int i = 0; i < length; i++)
            {
                int id = IDS[i];
                SceneGridNode node = Grid.Get(id);
                if (node == null)
                {
                    Grid.LogError(string.Format("节点:[{0},{1}]激活/隐藏九宫格时没有发现ID为:{1}的节点", Row, Column, id));
                }
                else
                {
                    node.SetActive(active);
                }
            }
        }

        public override string ToString()
        {
            return string.Format("索引:[{0},{1}],ID:{2}", Row, Column, ID);
        }
        #endregion

        #region 编辑器
#if UNITY_EDITOR
        private Vector3 center = Vector3.zero;

        private Color face = new Color(1, 0, 1, 0.1f);

        public void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.UIntField("行:", ref row, obj);
            UIEditLayout.UIntField("列:", ref column, obj);
            UIEditLayout.Vector3Field("左下角点:", ref leftDownPoint, obj);
            UIEditLayout.Vector3Field("右上角点:", ref rightUpPoint, obj);
        }

        /// <summary>
        /// 在场景视图绘制UI
        /// </summary>
        /// <param name="view"></param>
        public void OnSceneGUI(SceneView view)
        {
            UIHandleTool.DrawRectangle(leftDownPoint, rightUpPoint, face, Color.yellow);
            center = (leftDownPoint + rightUpPoint) * 0.5f;
            Handles.Label(center, string.Format("[{0},{1}]", row, column));
        }
#endif
        #endregion
    }
}