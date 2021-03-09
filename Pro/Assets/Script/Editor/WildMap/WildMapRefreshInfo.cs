using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Edit
{

    /// <summary>
    /// AU:Loong
    /// TM:2016.08.15
    /// BG:刷新信息
    /// </summary>
    [System.Serializable]
    public class WildMapRefreshInfo : IDraw, IDrawScene
    {
        #region 字段
        private Vector3 center = Vector3.zero;

        /// <summary>
        /// 列字典
        /// </summary>
        private static Dictionary<string, int> columnDic = new Dictionary<string, int>();

        /// <summary>
        /// 刷新序列ID字符
        /// </summary>
        public const string IDStr = "刷新序列";

        /// <summary>
        /// 左下角点字符
        /// </summary>
        public const string LeftDownPointStr = "左下角点";

        /// <summary>
        /// 右下角点字符
        /// </summary>
        public const string RightUpPointStr = "右上角点";

        /// <summary>
        /// 行号
        /// </summary>
        public int rowIdx = -1;

        /// <summary>
        /// 刷新序列ID
        /// </summary>
        public int refreshId = 0;

        /// <summary>
        /// 区域长度半径
        /// </summary>
        public Vector3 leftDownPoint = Vector3.zero;
        /// <summary>
        /// 区域宽度半径
        /// </summary>
        public Vector3 rightUpPoint = Vector3.zero;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public WildMapRefreshInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Focus()
        {
            Vector3 center = (leftDownPoint + rightUpPoint) * 0.5f;
            SceneViewUtil.Focus(center);
            UIEditTip.Log("已聚焦");
        }

        public void Draw(UnityEngine.Object obj, IList lst, int idx)
        {
            UIEditLayout.UIntField("刷新序列ID:", ref refreshId, obj);
            if (refreshId < 1) EditorGUILayout.HelpBox("请输入有效序列", MessageType.Error);
            UIEditLayout.Vector3Field("左下角点:", ref leftDownPoint, obj);
            UIEditLayout.Vector3Field("右上角点:", ref rightUpPoint, obj);
        }


        public void Read(ISheet sheet)
        {
            if (sheet == null) return;
            if (rowIdx == -1) return;
            IRow row = sheet.GetRow(rowIdx);
            if (columnDic[IDStr] != -1) refreshId = ExcelTool.ReadInt(row, columnDic[IDStr]);
            if (columnDic[LeftDownPointStr] != -1) leftDownPoint = ExcelTool.ReadVector3(row, columnDic[LeftDownPointStr], ',', 100, true);
            if (columnDic[RightUpPointStr] != -1) rightUpPoint = ExcelTool.ReadVector3(row, columnDic[RightUpPointStr], ',', 100, true);

        }

        public void Write(ISheet sheet)
        {
            if (sheet == null) return;
            IRow row = null;
            rowIdx = ExcelTool.GetRow(sheet, 0, refreshId.ToString());
            if (rowIdx == -1)
            {
                row = sheet.CreateRow(sheet.PhysicalNumberOfRows);
                rowIdx = sheet.PhysicalNumberOfRows;
            }
            else
            {
                row = sheet.GetRow(rowIdx);
            }
            if (columnDic[IDStr] != -1) ExcelTool.WriteInt(row, columnDic[IDStr], refreshId);
            if (columnDic[LeftDownPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[LeftDownPointStr], leftDownPoint, ',', 100, true);
            if (columnDic[RightUpPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[RightUpPointStr], rightUpPoint, ',', 100, true);
        }

        public void OnSceneGUI(Object obj)
        {

            UIHandleTool.DrawRectangle(leftDownPoint, rightUpPoint, obj);

            center = (leftDownPoint + rightUpPoint) * 0.5f;
            var gColor = GUI.color;
            GUI.color = Color.magenta;
            string tip = string.Format("刷新序列ID:{0}", refreshId);
            Handles.Label(center, tip);
            GUI.color = gColor;
        }

        public void OnSceneSelect(Object obj)
        {
            if (Event.current == null) return;
            UIVectorUtil.Set(obj, ref leftDownPoint, "左下角点", Event.current.shift, 0);
            UIVectorUtil.Set(obj, ref rightUpPoint, "右上角点", Event.current.control, 0);
        }

        /// <summary>
        /// 设置列字典
        /// </summary>
        public static void SetColumnDic(ISheet sheet)
        {
            columnDic.Clear();
            columnDic.Add(IDStr, -1);
            columnDic.Add(LeftDownPointStr, -1);
            columnDic.Add(RightUpPointStr, -1);
            ExcelTool.SetColumnDic(sheet, columnDic);
        }

        /// <summary>
        /// 清理列字典
        /// </summary>
        public static void ClearColumnDic()
        {
            columnDic.Clear();
        }
        #endregion
    }
}