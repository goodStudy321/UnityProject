//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/9/27 10:25:11
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
    /// LuaProtoItem
    /// </summary>
    [Serializable]
    public class LuaProtoItem : SelectInfo
    {
        #region 字段

        public string name;

        public string fullPath = null;


        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public LuaProtoItem()
        {

        }

        public LuaProtoItem(string path, string name)
        {
            fullPath = path;
            this.name = name;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Gen()
        {
            var exePath = LuaExcelSelectView.Exe;
            if (!File.Exists(exePath))
            {
                UIEditTip.Error("{0} not exist!", exePath);
            }
            else
            {
                var filePath = "\"" + fullPath + "\"";
                ProcessUtil.Execute(exePath, filePath, wairForExit: false);
            }
        }

        public void GenDialog()
        {
            var msg = string.Format("确定生成:{0}", fullPath);
            DialogUtil.Show("", msg, Gen);
        }

        public override void OnGUI(Object obj)
        {
            EditorGUILayout.LabelField(name);
            GUILayout.FlexibleSpace();
            var e = Event.current;
            if (GUILayoutUtility.GetLastRect().Contains(e.mousePosition))
            {
                if (e.type == EventType.MouseDown)
                {
                    e.Use();
                }
            }

        }
        #endregion
    }
}