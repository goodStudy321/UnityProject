using System.IO;
using Loong.Game;
using System.Text;
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
    /// TM:2016.08.13
    /// BG:安全区域和入口编辑窗口
    /// </summary>
    public class WildMapAreaView : WildMapEditView
    {
        #region 字段
        /// <summary>
        /// 列名和列行字典
        /// </summary>
        private Dictionary<string, int> columnDic = new Dictionary<string, int>();

        private string bornPointStr = "出生点坐标";
        private string exitPointStr = "出口坐标";
        private string leftDownPointStr = "左下角点";
        private string rightUpPointStr = "右上角点";

        /// <summary>
        /// 出生点
        /// </summary>
        public Vector3 bornPoint = Vector3.zero;
        /// <summary>
        /// 出口坐标
        /// </summary>
        public Vector3 exitPoint = Vector3.zero;
        /// <summary>
        /// 左下角点
        /// </summary>
        public Vector3 leftDownPoint = Vector3.zero;
        /// <summary>
        /// 右上角点
        /// </summary>
        public Vector3 rightUpPoint = Vector3.zero;

        #endregion

        #region 属性
        public override string SheetName
        {
            get
            {
                return "Sheet1";
            }
        }

        protected override string RelativePath
        {
            get
            {
                return "../table/C 场景设置表.xls";
            }
        }
        #endregion

        #region 私有方法
        private void DrawAreaConfig()
        {
            EditorGUILayout.HelpBox("1,通过Ctrl+右键点击,可快速设置出生点\n2,通过Shift+右键点击,可快速设置出口坐标\n3,通过Alt+右键点击,可快速设置左下角点\n4,通过Ctrl+中键点击,可快速设置右上角点", MessageType.Info);
            UIEditLayout.Vector3Field("出生点:", ref bornPoint, this);
            UIEditLayout.Vector3Field("出口坐标:", ref exitPoint, this);
            UIEditLayout.Vector3Field("左下角点:", ref leftDownPoint, this);
            UIEditLayout.Vector3Field("右上角点:", ref rightUpPoint, this);
        }

        /// <summary>
        /// 设置列名和列字典
        /// </summary>
        private void SetColumnDic(ISheet sheet)
        {
            columnDic.Clear();
            columnDic.Add(bornPointStr, -1);
            columnDic.Add(exitPointStr, -1);
            columnDic.Add(leftDownPointStr, -1);
            columnDic.Add(rightUpPointStr, -1);
            ExcelTool.SetColumnDic(sheet, columnDic);
        }

        #endregion

        #region 保护方法
        protected override void OpenCustom()
        {
            base.OpenCustom();
            Win.SetTitle("安全区域和入口窗口");
            Win.SetSize(600, 600);
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical("flow background");
            if (e.type == EventType.ContextClick) ContextClick();
            DrawAreaConfig();
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndVertical();
        }
        protected override void Read()
        {
            IWorkbook workBook = ExcelTool.GetWrokBook(FullPath, SheetName);
            if (workBook == null) return;
            ISheet sheet = workBook.GetSheet(SheetName);
            SetColumnDic(sheet);
            /*SetSceneRow(sheet, sceneID);
            if (!CheckSceneRow()) return;*/
            IRow row = null;//sheet.GetRow(sceneRow);
            if (columnDic[bornPointStr] != -1) bornPoint = ExcelTool.ReadVector3(row, columnDic[bornPointStr], ',', 100, true);
            if (columnDic[exitPointStr] != -1) exitPoint = ExcelTool.ReadVector3(row, columnDic[exitPointStr], ',', 100, true);
            if (columnDic[leftDownPointStr] != -1) leftDownPoint = ExcelTool.ReadVector3(row, columnDic[leftDownPointStr], ',', 100, true);
            if (columnDic[rightUpPointStr] != -1) rightUpPoint = ExcelTool.ReadVector3(row, columnDic[rightUpPointStr], ',', 100, true);

            workBook.Close();
            UIEditTip.Log("读取Excel数据成功");
        }

        protected override void Write()
        {
            IWorkbook workBook = ExcelTool.GetWrokBook(FullPath, SheetName);
            if (workBook == null) return;
            ISheet sheet = workBook.GetSheet(SheetName);
            SetColumnDic(sheet);
            /*SetSceneRow(sheet, sceneID);
            if (!CheckSceneRow()) return;*/
            IRow row = null;//sheet.GetRow(sceneRow);
            if (columnDic[bornPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[bornPointStr], bornPoint, ',', 100, true);
            if (columnDic[exitPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[exitPointStr], exitPoint, ',', 100, true);
            if (columnDic[leftDownPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[leftDownPointStr], leftDownPoint, ',', 100, true);
            if (columnDic[rightUpPointStr] != -1) ExcelTool.WriteVector3(row, columnDic[rightUpPointStr], rightUpPoint, ',', 100, true);

            ExcelTool.Save(workBook, FullPath);

        }

        #endregion

        #region 公开方法

        public override void OnSceneGUI(SceneView sceneView)
        {
            if (e != null)
            {
                UIVectorUtil.Set(this, ref bornPoint, "出生位置", e.control);
                UIVectorUtil.Set(this, ref exitPoint, "出口坐标", e.shift);
                UIVectorUtil.Set(this, ref leftDownPoint, "左下角点", e.alt);
                UIVectorUtil.Set(this, ref rightUpPoint, "右上角点", e.control, 2);
            }
            Handles.color = Color.red;
            Handles.Label(bornPoint, "出生位置");
            Handles.SphereHandleCap(GetInstanceID(), bornPoint, Quaternion.identity, 1f, EventType.Repaint);
            Handles.color = Color.blue;
            Handles.Label(exitPoint, "出口坐标");
            Handles.SphereHandleCap(GetInstanceID(), exitPoint, Quaternion.identity, 1f, EventType.Repaint);
            Handles.color = Color.magenta;
            UIHandleTool.DrawRectangle(leftDownPoint, rightUpPoint, this);
            Handles.color = Color.white;
        }

        #endregion
    }
}