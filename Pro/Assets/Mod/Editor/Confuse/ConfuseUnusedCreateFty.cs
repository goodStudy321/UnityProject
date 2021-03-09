//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/29 12:16:53
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseUnusedCreate
    /// </summary>
    public static class ConfuseUnusedCreateFty
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static string Create(ICodeClass codeClass, int tap = 2)
        {
            if (codeClass == null) return "//NULL";
            var sb = new StringBuilder();
            CodeUtil.SetTap(sb, tap);
            var tap1 = tap + 1;
            sb.Append("try\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("{\n");

            //BEG_创建对象
            CodeUtil.SetTap(sb, tap1);

            var name = codeClass.Name;
            var f_name = "m_" + codeClass.Name.ToLower();
            sb.Append("var ").Append(f_name).Append(" = ");
            var baseName = codeClass.BaseClass;
            if (string.IsNullOrEmpty(baseName) || baseName == ConfuseCodeCfg.UnityObj)
            {
                sb.Append("new ").Append(name).Append("();");
            }
            else if (baseName == ConfuseCodeCfg.UnityMono)
            {
                sb.Append("new GameObject(\"").Append(name).Append("\").");
                sb.Append("AddComponent<").Append(name).Append(">();");
            }
            else if (baseName == ConfuseCodeCfg.UnityScripObj)
            {
                sb.Append("ScriptableObject.CreateInstance<").Append(name);
                sb.Append(">();");
            }

            sb.Append("\n");
            //END_创建对象
            //GameObject.DestroyImmediate(sc, true);

            //BEG_调用方法
            ICodeFunc func = null;
            var funcs = codeClass.Funcs;
            int length = funcs.Count;
            for (int i = 0; i < length; i++)
            {
                var f = funcs[i];
                if (f.AccessType != CSAccessType.Public) continue;
                func = f; break;
            }

            CodeUtil.SetTap(sb, tap1);
            sb.Append(f_name).Append(".").Append(func.Name).Append("(");
            var args = func.Args;
            length = args.Count;
            var last = length - 1;
            for (int i = 0; i < length; i++)
            {
                var arg = args[i];
                var str = CodeUtil.GetRandomDefault(arg.Type);
                sb.Append(str);
                if (i < last) sb.Append(", ");
            }

            sb.Append(");\n");
            //END_调用方法

            if (!string.IsNullOrEmpty(baseName))
            {
                CodeUtil.SetTap(sb, tap1);
                sb.Append("GameObject.DestroyImmediate(");
                sb.Append(f_name).Append(", true);\n");
            }
            CodeUtil.SetTap(sb, tap);
            sb.Append("}\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("catch (Exception)\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("{\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("}\n");
            return sb.ToString();
        }


        public static string Create(List<ICodeClass> codeClasses, int tap = 2)
        {
            var it = CodeUtil.GetRandomIt<ICodeClass>(codeClasses, true);
            return Create(it, tap);
        }
        #endregion
    }
}