using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        2677dd06-b503-4ef5-9f93-36403e1ea62d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/5 19:32:48
    /// BG:场景触发器编辑窗口
    /// </summary>
    public class SceneTriggerEditView : ExcelEditView
    {
        #region 字段

        /// <summary>
        /// 右上角坐标
        /// </summary>
        private Vector3 rightUpCoord = Vector3.zero;

        /// <summary>
        /// 左下角坐标
        /// </summary>
        private Vector3 leftDownCoord = Vector3.zero;

        /// <summary>
        /// 右上角坐标字符
        /// </summary>
        private string rightUpCoordStr = "右上角坐标";

        /// <summary>
        /// 左下角坐标字符
        /// </summary>
        private string leftDownCoordStr = "左下角坐标";


        private SceneTrigger st;

        #endregion

        #region 属性

        protected override string RelativePath
        {
            get
            {
                return "../table/C 场景Trigger配置表.xls";
            }
        }

        /// <summary>
        /// 选择触发信息
        /// </summary>
        public SceneTrigger ST
        {
            get { return st; }
            set { st = value; }
        }


        /// <summary>
        /// 列名和列字典
        /// </summary>
        private Dictionary<string, int> columnDic = new Dictionary<string, int>();

        #endregion

        #region 构造方法
        public SceneTriggerEditView()
        {

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 设置列名和列字典
        /// </summary>
        private void SetColumnDic(ISheet sheet)
        {
            columnDic.Clear();
            columnDic.Add(rightUpCoordStr, -1);
            columnDic.Add(leftDownCoordStr, -1);
            ExcelTool.SetColumnDic(sheet, columnDic);
        }

        private Vector3 ReadVector(SceneTrigger.vector3 arg, float factor = 0.01f)
        {
            Vector3 vec = Vector3.zero;
            float x = arg.x * factor;
            float z = arg.z * factor;
            vec.Set(x, 0, z);
            return vec;
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            UIEditLayout.HelpInfo("Ctrl+鼠标左键点击 可设置左下角点");
            UIEditLayout.HelpInfo("Ctrl+鼠标右键点击 可设置右上角点");
            UIEditLayout.Vector3Field("左下角坐标:", ref leftDownCoord, this);
            UIEditLayout.Vector3Field("右上角坐标:", ref rightUpCoord, this);
            if (e.type == EventType.ContextClick) ContextClick();
        }

        protected override void Return()
        {
            Win.Switch<SceneTriggerSelectView>();
        }

        protected override void Read()
        {
            leftDownCoord = ReadVector(st.left);
            rightUpCoord = ReadVector(st.right);
        }

        protected override void Write()
        {
            IWorkbook workBook = ExcelTool.GetWrokBook(FullPath, SheetName);
            if (workBook == null) return;
            ISheet sheet = workBook.GetSheet(SheetName);
            SetColumnDic(sheet);
            int rowIdx = ExcelTool.GetRow(sheet, 0, ST.iD.ToString());
            if (rowIdx == -1)
            {
                UIEditTip.Log("没有发现ID为:{0}的触发器", ST.iD);
                return;
            }
            IRow iRow = sheet.GetRow(rowIdx);
            if (columnDic[leftDownCoordStr] != -1)
            {
                ExcelTool.WriteVector3(iRow, columnDic[leftDownCoordStr], leftDownCoord, '|', 100, true);
            }
            if (columnDic[rightUpCoordStr] != -1)
            {
                ExcelTool.WriteVector3(iRow, columnDic[rightUpCoordStr], rightUpCoord, '|', 100, true);
            }

            ExcelTool.Save(workBook, FullPath);
            DataTool.MakeTable();
            Win.Get<SceneTriggerSelectView>().Load();
        }

        protected override void DrawSceneHandle()
        {
            UIHandleTool.DrawRectangle(leftDownCoord, rightUpCoord, this);
            if (e == null) return;
            UIVectorUtil.Set(this, ref leftDownCoord, "左下角坐标", e.control, 0);
            UIVectorUtil.Set(this, ref rightUpCoord, "右下角坐标", e.control, 1);
        }
        #endregion

        #region 公开方法
        public void Edit(SelectInfo info)
        {
            SceneTriggerSelectInfo stsi = info as SceneTriggerSelectInfo;
            ST = SceneTriggerManager.instance.Find(stsi.ID);
            Win.Switch<SceneTriggerEditView>();
        }


        public override void OnCompiled()
        {
            SceneTriggerSelectView sv = Win.Get<SceneTriggerSelectView>();
            SceneTriggerSelectInfo stsi = sv.Select as SceneTriggerSelectInfo;
            ST = SceneTriggerManager.instance.Find(stsi.ID);

        }
        #endregion
    }
}