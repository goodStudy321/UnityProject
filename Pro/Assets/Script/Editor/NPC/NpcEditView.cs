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
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        f6c928c8-612c-410a-b003-904537f954b8
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/5 12:01:02
    /// BG:NPC编辑视图
    /// </summary>
    public class NpcEditView : ExcelEditView
    {
        #region 字段
        [SerializeField]
        private int select = 0;

        /// <summary>
        /// 场景ID
        /// </summary>
        [SerializeField]
        private UInt32 sceneID = 0;

        /// <summary>
        /// NPC信息条目
        /// </summary>
        [SerializeField]
        private List<NpcItemInfo> infos = new List<NpcItemInfo>();
        #endregion

        #region 属性
        protected override string RelativePath
        {
            get
            {
                return "../Table/N NPC配置表.xls";
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置NPC信息列表
        /// </summary>
        /// <param name="sheet"></param>
        private void SetInfos(ISheet sheet)
        {
            infos.Clear();
            if (sheet == null) return;
            HashSet<string> hashSet = new HashSet<string>();

            SceneInfo si = SceneInfoManager.instance.Find(sceneID);
            int length = si.npcList.list.Count;
            for (int i = 0; i < length; i++)
            {
                hashSet.Add(si.npcList.list[i].ToString());
            }

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
                    NpcItemInfo info = new NpcItemInfo();
                    infos.Add(info); info.npcID = int.Parse(value);
                    info.row = index; info.Read(sheet);
                }
                index++;
            }
        }
        #endregion

        #region 保护方法

        protected override void OpenCustom()
        {
            base.OpenCustom();
            Win.SetTitle("Npc位置编辑窗口");
            Win.SetSize(600, Screen.currentResolution.height);
        }

        protected override void Read()
        {
            IWorkbook npcWorkbook = null;
            try
            {
                SceneInfoManager.instance.Load("table");
            }
            catch (Exception e)
            {
                string error = string.Format("加载:C 场景设置表.xls发生错误:{0}", e.Message);
                EditorUtility.DisplayDialog("", error, "确定");
                Win.Close(); return;
            }
            try
            {
                npcWorkbook = ExcelTool.GetWrokBook(FullPath, SheetName);
                if (npcWorkbook == null) return;
                ISheet npcSheet = npcWorkbook.GetSheet(SheetName);
                NpcItemInfo.SetColumnDic(npcSheet);
                SetInfos(npcSheet);
            }
            catch (System.Exception e)
            {
                UIEditTip.Error("Loong,打开Excel:{0},发生错误:{1}", FullPath, e.Message);
            }
            finally
            {
                if (npcWorkbook != null) npcWorkbook.Close();
            }
        }

        protected override void Write()
        {
            IWorkbook npcWorkbook = null;
            try
            {
                npcWorkbook = ExcelTool.GetWrokBook(FullPath, SheetName);
                if (npcWorkbook == null) return;
                ISheet npcSheet = npcWorkbook.GetSheet(SheetName);
                NpcItemInfo.SetColumnDic(npcSheet);
                int length = infos.Count;
                for (int i = 0; i < length; i++) infos[i].Write(npcSheet);
                ExcelTool.Save(npcWorkbook, FullPath);
            }
            catch (System.Exception e)
            {
                UIEditTip.Error("Loong，写入Excel:{0},发生错误:{1}", FullPath, e.Message);
            }
            finally
            {
                if (npcWorkbook != null) npcWorkbook.Close();
            }
        }


        protected override void OnGUICustom()
        {
            if (e.type == EventType.ContextClick) ContextClick();
            UIEditLayout.HelpInfo("1,通过Ctrl+左键快速设置Npc位置");
            UIEditLayout.HelpInfo("2,通过Shift+左键快速添加新Npc点");
            UIDrawTool.IDrawLst<NpcItemInfo>(this, infos, "npcItemInfos", "Npc列表");

        }

        protected override void DrawSceneGUI()
        {
            if (GUILayout.Button("聚焦"))
            {
                if (infos.Count > 0) SceneViewUtil.Focus(infos[select].pos);
                else UIEditTip.Warning("Npc数量为0,无法聚焦任何一个点");
            }
            UIDrawTool.Buttons(this, "Npc列表", "Npc位置", infos.Count, ref select);
        }

        protected override void DrawSceneHandle()
        {
            if (e != null)
            {
                UIVectorUtil.AddInfo<NpcItemInfo>(this, infos, "Npc位置", e.shift);
                UIVectorUtil.SetInfo<NpcItemInfo>(this, infos, select, "Npc位置", e.control, 0);
            }
            UIVectorUtil.DrawInfos<NpcItemInfo>(this, infos, Color.red, "Npc位置", select);
        }

        protected override void Return()
        {
            Win.Switch<SceneSelectView>();
        }
        #endregion

        #region 公开方法
        public void Edit(SelectInfo info)
        {
            SceneSelectInfo ssi = info as SceneSelectInfo;
            sceneID = ssi.ID;
            Win.Switch<NpcEditView>();
        }
        #endregion
    }
}