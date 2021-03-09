//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/9/27 10:21:18
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// LuaExcelView
    /// </summary>
    public class LuaExcelSelectView : SelectViewBase<LuaProtoItem>
    {
        #region 字段

        #endregion

        #region 属性
        public static string Exe
        {
            get
            {
                var exePath = "../Table/Client/lua/exe/Loong.Excel.Lua.exe";
                exePath = Path.GetFullPath(exePath);
                return exePath;
            }
        }

        public override bool CanMultiSelect
        {
            get
            {
                return true;
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void GenSingle()
        {
            if (Select == null) return;
            Select.GenDialog();
        }

        private void GenAll()
        {
            DataTool.MakeLua();
        }

        private void GenMulti()
        {
            int length = infos.Count;
            if (length < 1)
            {
                UIEditTip.Log("没有任何协议文件"); return;
            }
            var sb = new StringBuilder();
            for (int i = 0; i < length; i++)
            {
                var it = infos[i];
                if (!it.IsSelect) continue;
                if (sb.Length > 0) sb.Append(" ");
                sb.Append("\"").Append(it.fullPath).Append("\"");
            }
            if (sb.Length < 1)
            {
                UIEditTip.Log("没有选中任何协议文件");
            }
            else
            {
                var arg = sb.ToString();
                ProcessUtil.Execute(Exe, arg, wairForExit: false);
            }
        }
        #endregion

        #region 保护方法

        protected void GenAllDialog()
        {
            DialogUtil.Show("", "生成所有协议?", GenAll);
        }

        protected void GenMultiDialog()
        {
            DialogUtil.Show("", "生成已选中的协议?", GenMulti);
        }

        protected override void SetInfos()
        {
            var dir = "../Table/client/lua/proto";
            dir = Path.GetFullPath(dir);
            if (!Directory.Exists(dir))
            {
                iTrace.Error("Loong", "LuaProtoDir:{0} not exist!", dir); return;
            }
            infos.Clear();
            var files = Directory.GetFiles(dir, "*.xml");
            if (files == null || files.Length < 1) return;
            Array.Sort<string>(files, string.Compare);
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var name = Path.GetFileName(file);
                var it = new LuaProtoItem(file, name);
                infos.Add(it);
            }
        }

        protected override string NormalStyle()
        {
            return StyleTool.Node0;
        }

        protected override void EditCustom(LuaProtoItem info)
        {
            UIEditTip.Log("未实现");
        }


        protected override void ContextClickCustom(GenericMenu menu)
        {
            menu.AddItem("生成", false, GenSingle);
            menu.AddItem("生成所有", false, GenAllDialog);
            menu.AddItem("生成多个", false, GenMultiDialog);
        }

        protected override void Title()
        {
            BegTitle();
            TitleHelp();
            if (TitleBtn("生成所有")) GenAllDialog();
            if (TitleBtn("生成多个")) GenMultiDialog();
            EndTitle();
        }

        protected override void Help()
        {
            var msg = "请查阅:文档/程序/客户端/工具/客户端Excel导出lua说明.docx";
            DialogUtil.Show("", msg);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}