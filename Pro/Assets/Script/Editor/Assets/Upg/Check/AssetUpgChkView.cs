/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/21 3:35:05
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Md5Dic = Dictionary<string, Md5Info>;
    /// <summary>
    /// AssetUpgChkView
    /// </summary>
    public class AssetUpgChkView : EditViewBase
    {
        #region 字段
        public long total = 0L;

        public string totalStr = null;

        public long delSize = 0L;

        public string delStr = null;

        public long changeSize = 0L;

        public string changeStr = null;

        public long changeDifSize = 0L;

        public string changeDifStr = null;

        public long incresedSize = 0L;

        public string incresedStr = null;


        public bool isComp = true;

        public string oldPath = null;

        public string newPath = null;

        public string savePath = "";

        public string srcToXmlPath = "";

        public string destToXmlPath = "";

        public string dir = "../AssetsUpgChk";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void ToXML()
        {
            if (File.Exists(srcToXmlPath))
            {
                var defaultName = GetDefaultName(AssetMf.Name);
                var xmlPath = EditorUtility.SaveFilePanel("保存XML", "../", defaultName, "xml");
                if (string.IsNullOrEmpty(xmlPath))
                {
                    UIEditTip.Log("已取消");
                }
                else
                {
                    destToXmlPath = xmlPath;
                    AssetMfUtil.ToXML(srcToXmlPath, xmlPath, isComp);
                }
            }
            else
            {
                UIEditTip.Log("{0} not exist!", srcToXmlPath);
            }
        }
        private void Check()
        {
            var defaultName = GetDefaultName(AssetMfUtil.chkUpgName);
            var fullDir = Path.GetFullPath(dir);
            var path = EditorUtility.SaveFilePanel("设置升级清单路径", fullDir, defaultName, "xml");
            if (string.IsNullOrEmpty(path))
            {
                UIEditTip.Log("已取消"); return;
            }
            savePath = path;
            Md5Dic oldDic = null;
            var info = AssetMfUtil.CheckUpg(oldPath, newPath, path, isComp, ref oldDic);
            if (info == null)
            {
                UIEditTip.Log("无更新");
            }
            else
            {
                delSize = GetSize(info.deleted);
                changeSize = GetSize(info.changed);
                incresedSize = GetSize(info.incresed);
                total = incresedSize + changeSize - delSize;
                totalStr = ByteUtil.GetSizeStr(total);
                delStr = ByteUtil.GetSizeStr(delSize);
                changeStr = ByteUtil.GetSizeStr(changeSize);
                incresedStr = ByteUtil.GetSizeStr(incresedSize);

                var oldChangeSize = GetSize(info.changed, oldDic);
                changeDifSize = changeSize - oldChangeSize;
                changeDifStr = ByteUtil.GetSizeStr(changeDifSize);

                UIEditTip.Log("已更新");
            }
        }

        private long GetSize(List<Md5Info> infos)
        {
            if (infos == null) return 0L;
            long total = 0L;
            int len = infos.Count;
            for (int i = 0; i < len; i++)
            {
                total += infos[i].Sz;
            }
            return total;
        }

        private long GetSize(List<Md5Info> infos, Md5Dic dic)
        {
            if (infos == null || dic == null) return 0L;
            long total = 0L;
            int len = infos.Count;
            for (int i = 0; i < len; i++)
            {
                var info = infos[i];
                if (dic.ContainsKey(info.path))
                {
                    var oldInfo = dic[info.path];
                    total += oldInfo.Sz;
                }
            }
            return total;
        }

        private void OpenUpg()
        {
            ProcessUtil.Execute(savePath);
        }

        private string GetDefaultName(string name)
        {
            return AssetPathUtil.GetNowName(name);
        }

        private void DrawSize(string des, long size, string sizeStr)
        {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(des);
            EditorGUILayout.LongField(size);
            EditorGUILayout.LabelField(sizeStr);
            EditorGUILayout.EndHorizontal();
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (TitleBtn("检查"))
            {
                Check();
            }
            else if (TitleBtn("打开"))
            {
                OpenUpg();
            }
            EditorGUILayout.EndHorizontal();
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.Toggle("清单是否压缩", ref isComp, this);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            DrawSize("总量", total, totalStr);
            DrawSize("删除", delSize, delStr);
            DrawSize("改变", changeSize, changeStr);
            DrawSize("改变差异", changeDifSize, changeDifStr);
            DrawSize("新增", incresedSize, incresedStr);
            EditorGUILayout.EndVertical();

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();

            UIEditLayout.SetPath("开始清单文件:", ref oldPath, this, "xml");
            UIEditLayout.SetPath("结束清单文件:", ref newPath, this, "xml");
            UIEditLayout.SetFolder("信息默认保存目录:", ref dir, this);
            UIEditLayout.SetPath("上次保存升级信息:", ref savePath, this, "xml");
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.SetPath("转换XML源清单:", ref srcToXmlPath, this, "xml");
            if (GUILayout.Button("转换", UIOptUtil.btn)) ToXML();

            EditorGUILayout.EndHorizontal();
            UIEditLayout.SetPath("转换XML后清单:", ref destToXmlPath, this, "xml");

        }
        #endregion

        #region 公开方法

        #endregion
    }
}