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
     * GUID:        4c468485-c2e2-4f58-b7a2-c043da9ef713
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 12:06:46
    /// BG:路径移动编辑视图
    /// </summary>
    public class PathPointEditView : ExcelEditView
    {
        #region 字段
        private string pointsStr = "路径";

        private PathInfo selectInfo = null;

        [SerializeField]
        private EditPathPointInfo editPointsInfo = new EditPathPointInfo();


        private Dictionary<string, int> columnDic = new Dictionary<string, int>();
        #endregion

        #region 属性
        protected override string RelativePath
        {
            get
            {
                return "../table/L 路径点.xls";
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 设置列名和列字典
        /// </summary>
        private void SetColumnDic(ISheet sheet)
        {
            columnDic.Clear();
            columnDic.Add(pointsStr, -1);
            ExcelTool.SetColumnDic(sheet, columnDic);
        }
        private PathInfo GetPointsInfo()
        {
            PathPointSelectView selectView = Win.Get<PathPointSelectView>();
            PathPointSelectInfo selectInfo = selectView.Select as PathPointSelectInfo;
            PathInfo pathMoveInfo = PathInfoManager.instance.Find(selectInfo.ID);
            if (pathMoveInfo == null)
            {
                iTrace.Error("Loong", string.Format("没有发现ID为:{0}的点列表信息", selectInfo.ID));
            }
            return pathMoveInfo;
        }
        #endregion

        #region 保护方法

        protected override void OnGUICustom()
        {
            if (e.type == EventType.ContextClick) ContextClick();
            UIEditLayout.HelpInfo("使用Ctrl+左键点击 可设置点");
            UIEditLayout.HelpInfo("使用Shift+左键点击 可添加点");
            editPointsInfo.OnGUI(this);
        }
        protected override void OpenCustom()
        {
            base.OpenCustom();
            Win.SetTitle("点列表编辑窗口");
        }

        protected override void Read()
        {
            selectInfo = GetPointsInfo();
            editPointsInfo.Read(selectInfo);
        }

        protected override void Write()
        {
            IWorkbook workBook = ExcelTool.GetWrokBook(FullPath, SheetName);
            if (workBook == null) return;
            ISheet sheet = workBook.GetSheet(SheetName);
            SetColumnDic(sheet);
            int rowIdx = ExcelTool.GetRow(sheet, 0, selectInfo.id.ToString());
            if (rowIdx == -1)
            {
                UIEditTip.Error("没有发现路径点ID为:{0}的条目", selectInfo.id);
                workBook.Close();
                return;
            }
            IRow iRow = sheet.GetRow(rowIdx);
            if (columnDic[pointsStr] != -1)
            {
                string pointsValue = editPointsInfo.ToString();
                ExcelTool.WriteString(iRow, columnDic[pointsStr], pointsValue);
            }
            ExcelTool.Save(workBook, FullPath);
            DataTool.MakeTable();
            PathInfoManager.instance.Load("table");
        }

        protected override void Return()
        {
            Win.Switch<PathPointSelectView>();
        }

        protected override void DrawSceneGUI()
        {
            editPointsInfo.DrawSceneGUI(this);
        }

        protected override void DrawSceneHandle()
        {
            editPointsInfo.DrawSceneHandle(this);
        }
        #endregion

        #region 公开方法
        public void Edit(SelectInfo info)
        {
            Win.Switch<PathPointEditView>();
        }

        public override void OnCompiled()
        {
            PathInfoManager.instance.Load("table");
        }
        #endregion
    }
}