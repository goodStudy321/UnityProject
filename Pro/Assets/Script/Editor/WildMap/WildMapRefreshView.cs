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
    /// TM:2016.08.13
    /// BG:刷新列表窗口
    /// </summary>
    public class WildMapRefreshView : WildMapEditView
    {
        #region 字段
        /// <summary>
        /// 选择
        /// </summary>
        [SerializeField]
        private int select = 0;


        private Vector2 btnScroll = Vector2.zero;

        /// <summary>
        /// 刷新列表
        /// </summary>
        [SerializeField]
        private List<WildMapRefreshInfo> infos = new List<WildMapRefreshInfo>();

        /// <summary>
        /// 刷新序列字符
        /// </summary>
        public const string refreshStr = "刷新序列";

        #endregion

        #region 属性

        public override string SheetName
        {
            get
            {
                return "刷新列表";
            }
        }

        protected override string RelativePath
        {
            get
            {
                return "../table/Y 野外地图.xls";
            }
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 设置刷新列表
        /// </summary>
        /// <param name="sheet">刷新列表工作簿</param>
        /// <param name="lst">刷新ID列表</param>
        private void SetRefreshInfos(ISheet sheet, List<int> lst)
        {
            if (sheet == null) return;
            if (lst == null || lst.Count == 0) return;
            HashSet<string> hashSet = new HashSet<string>();
            int length = lst.Count;
            for (int i = 0; i < length; i++) hashSet.Add(lst[i].ToString());
            IEnumerator rowEnum = sheet.GetRowEnumerator();
            int index = 0;
            while (rowEnum.MoveNext())
            {
                IRow row = rowEnum.Current as IRow;
                if (row == null) break;
                ICell cell = row.GetCell(0);
                if (cell == null) break;
                string value = cell.ToString();
                if (hashSet.Contains(value))
                {
                    WildMapRefreshInfo info = new WildMapRefreshInfo();
                    infos.Add(info);
                    info.rowIdx = index;
                    info.Read(sheet);
                }
                index++;
            }
        }

        /// <summary>
        /// 获取刷新列表ID列表
        /// </summary>
        /// <param name="type"></param>
        /// <returns></returns>
        private List<int> GetRefreshIDLst()
        {
            int length = infos.Count;
            if (length == 0) return null;
            List<int> lst = new List<int>();
            for (int i = 0; i < length; i++)
            {
                WildMapRefreshInfo info = infos[i];
                lst.Add(info.refreshId);
            }
            return lst;
        }

        /// <summary>
        /// 读取刷新ID列表
        /// </summary>
        /// <param name="sheet">工作表</param>
        /// <param name="refreshStr">刷新字符</param>
        /// <returns></returns>
        private List<int> ReadRefreshID(ISheet sheet)
        {
            int refreshColumn = ExcelTool.GetColumn(sheet, 0, refreshStr);
            IRow row = sheet.GetRow(SceneRow);
            List<int> lst = ExcelTool.ReadInts(row, refreshColumn, ',');
            return lst;
        }

        /// <summary>
        /// 写入刷新ID列表
        /// </summary>
        /// <param name="sheet"></param>
        /// <param name="refreshStr"></param>
        /// <param name="type"></param>
        private void WriteRefreshID(ISheet sheet)
        {
            int refreshColumn = ExcelTool.GetColumn(sheet, 0, refreshStr);
            IRow row = sheet.GetRow(SceneRow);
            List<int> lst = GetRefreshIDLst();
            ExcelTool.WriteInts(row, refreshColumn, lst, ',');
        }

        /// <summary>
        /// 获取场景刷新区域表单
        /// </summary>
        /// <returns></returns>
        private ISheet GetAreaSheet(IWorkbook workbook, string sheetName)
        {
            if (workbook == null) return null;
            ISheet areaSheet = workbook.GetSheet(sheetName);
            if (areaSheet == null) return null;
            SceneRow = ExcelTool.GetRow(areaSheet, 0, SI.id.ToString());
            return areaSheet;
        }


        #endregion

        #region 保护方法
        protected override void OpenCustom()
        {
            base.OpenCustom();
            Win.SetTitle("刷新列表窗口");
            Win.SetSize(600, Screen.currentResolution.height);
            select = 0;
        }

        protected override void CloseCustom()
        {
            base.CloseCustom();
            WildMapRefreshInfo.ClearColumnDic();
        }

        protected override void Read()
        {
            IWorkbook areaWorkbook = null; IWorkbook refreshWorkbook = null;
            try
            {
                infos.Clear();
                string areaSheetName = Win.Get<WildMapAreaView>().SheetName;
                areaWorkbook = ExcelTool.GetWrokBook(Win.Get<WildMapAreaView>().FullPath, areaSheetName);
                ISheet areaSheet = GetAreaSheet(areaWorkbook, areaSheetName);
                if (areaSheet == null) return;
                List<int> ids = ReadRefreshID(areaSheet);

                refreshWorkbook = ExcelTool.GetWrokBook(FullPath, SheetName);
                if (refreshWorkbook == null) return;
                ISheet sheet = refreshWorkbook.GetSheet(SheetName);
                WildMapRefreshInfo.SetColumnDic(sheet);
                SetRefreshInfos(sheet, ids);
            }
            catch (System.Exception e)
            {
                UIEditTip.Error("Loong,打开Excel发生错误:{0}", e.Message);
            }
            finally
            {
                if (areaWorkbook != null) areaWorkbook.Close();
                if (refreshWorkbook != null) refreshWorkbook.Close();
            }
        }

        protected override void Write()
        {
            IWorkbook areaWorkbook = null; IWorkbook refreshWorkbook = null;
            try
            {
                string areaSheetName = Win.Get<WildMapAreaView>().SheetName;
                areaWorkbook = ExcelTool.GetWrokBook(Win.Get<WildMapAreaView>().FullPath, areaSheetName);
                ISheet areaSheet = GetAreaSheet(areaWorkbook, areaSheetName);
                if (areaSheet == null) return;

                WriteRefreshID(areaSheet);

                refreshWorkbook = ExcelTool.GetWrokBook(FullPath, SheetName);
                if (refreshWorkbook == null) return;
                ISheet refreshSheet = refreshWorkbook.GetSheet(SheetName);
                if (refreshSheet == null) return;
                int length = infos.Count;
                for (int i = 0; i < length; i++) infos[i].Write(refreshSheet);
                ExcelTool.Save(refreshWorkbook, FullPath);
            }
            catch (System.Exception e)
            {
                UIEditTip.Error("Loong,写入Excel发生错误:{0}", e.Message);
            }
            finally
            {
                if (areaWorkbook != null) areaWorkbook.Close();
                if (refreshWorkbook != null) refreshWorkbook.Close();
            }

        }

        protected override void OnGUICustom()
        {
            if (e.type == EventType.ContextClick) ContextClick();
            UIEditLayout.HelpInfo("可通过Shift+左键点击,快速设置左下角点");
            UIEditLayout.HelpInfo("可通过Ctrl+左键点击,快速设置右上角点");
            UIDrawTool.IDrawLst<WildMapRefreshInfo>(this, infos, "WildMapRefreshInfo", "刷新区域列表");

        }

        protected override void DrawSceneGUI()
        {
            if (GUILayout.Button("聚焦"))
            {
                if (infos.Count == 0) return;
                if (select < infos.Count) infos[select].Focus();
            }
            btnScroll = EditorGUILayout.BeginScrollView(btnScroll);
            UIDrawTool.Buttons(this, "刷新点列表", "刷新点", infos.Count, ref select);
            EditorGUILayout.EndScrollView();
        }

        protected override void DrawSceneHandle()
        {
            UISceneTool.Draw<WildMapRefreshInfo>(this, infos, select, Color.magenta);
        }
        #endregion

        #region 公开方法
        public override void Edit(SelectInfo info)
        {
            base.Edit(info);
            Win.Switch<WildMapRefreshView>();
        }
        #endregion
    }
}