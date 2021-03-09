using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;


namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        e5c3847d-951e-41f6-9720-99debc9c201e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/5 14:38:03
    /// BG:Npc编辑条目信息
    /// </summary>
    [System.Serializable]
    public class NpcItemInfo : VectorInfo, IDraw
    {
        #region 字段
        private Vector3 euler = Vector3.zero;
        /// <summary>
        /// 所在行
        /// </summary>
        public int row = -1;

        /// <summary>
        /// NPCID
        /// </summary>
        public int npcID = 0;

        /// <summary>
        /// 朝向
        /// </summary>
        public int eulerY = 0;

        /// <summary>
        /// 位置坐标字符
        /// </summary>
        public const string PointStr = "坐标";

        /// <summary>
        /// 旋转朝向字符
        /// </summary>
        public const string EulerStr = "旋转朝向";

        private static Dictionary<string, int> columnDic = new Dictionary<string, int>();

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public NpcItemInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Read(ISheet sheet)
        {
            if (sheet == null) return;
            if (row == -1) return;
            IRow iRow = sheet.GetRow(row);
            if (columnDic[EulerStr] != -1) eulerY = ExcelTool.ReadInt(iRow, columnDic[EulerStr]);
            if (columnDic[PointStr] != -1) pos = ExcelTool.ReadVector3(iRow, columnDic[PointStr], ',', 100);
        }

        public void Write(ISheet sheet)
        {
            if (sheet == null) return;
            IRow iRow = null;
            row = ExcelTool.GetRow(sheet, 0, npcID.ToString());
            if (row == -1)
            {
                iRow = sheet.CreateRow(sheet.PhysicalNumberOfRows);
                row = sheet.PhysicalNumberOfRows;
                ExcelTool.WriteInt(iRow, 0, npcID);
            }
            else
            {
                iRow = sheet.GetRow(row);
            }
            if (columnDic[EulerStr] != -1) ExcelTool.WriteInt(iRow, columnDic[EulerStr], eulerY);
            if (columnDic[PointStr] != -1) ExcelTool.WriteVector3(iRow, columnDic[PointStr], pos, ',', 100);
        }


        public void Draw(UnityEngine.Object obj, IList lst, int idx)
        {
            UIEditLayout.UIntField("NpcID:", ref npcID, obj);
            if (npcID < 1) UIEditLayout.HelpError("请输入有效ID");
            UIEditLayout.Vector3Field(PointStr, ref pos, obj);
            UIEditLayout.IntSlider("旋转朝向:", ref eulerY, 0, 360, obj);
        }

        public override void OnSceneGUI(UnityEngine.Object obj)
        {
            euler.Set(0, eulerY, 0);
            var gColor = GUI.color;
            GUI.color = Color.green;
            Handles.Label(pos + Vector3.one, "NpcID:" + npcID);
            Handles.ArrowHandleCap(obj.GetInstanceID(), pos, Quaternion.Euler(euler), 4f, EventType.Repaint);
            Handles.SphereHandleCap(obj.GetInstanceID(), pos, Quaternion.identity, 1, EventType.Repaint);
            GUI.color = gColor;
        }

        public static void SetColumnDic(ISheet sheet)
        {
            columnDic.Clear();
            columnDic.Add(PointStr, -1);
            columnDic.Add(EulerStr, -1);
            ExcelTool.SetColumnDic(sheet, columnDic);
        }
        #endregion
    }
}