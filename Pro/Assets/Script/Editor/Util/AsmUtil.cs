//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 10:35:03
//=============================================================================

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using AsmDic = Dictionary<string, Assembly>;

    /// <summary>
    /// 程序集工具
    /// </summary>
    public static class AsmUtil
    {
        #region 字段
        public const int Pri = ScriptUtil.Pri + 20;

        public const string Menu = ScriptUtil.Menu + "程序集/";

        public const string AMenu = ScriptUtil.AMenu + "程序集/";


        private static AsmDic dic = null;

        private static Assembly cs = null;

        private static Assembly cs_Editor = null;

        private static string cs_AsmPath = null;

        #endregion

        #region 属性
        /// <summary>
        /// k:程序集名,v:程序集
        /// </summary>
        public static AsmDic Dic
        {
            get
            {
                if (dic == null) dic = GetDic();
                return dic;
            }
        }

        /// <summary>
        /// Assembly-CSharp
        /// </summary>
        public static Assembly CS
        {
            get
            {
                if (cs == null) cs = Get("Assembly-CSharp");
                return cs;
            }
        }


        /// <summary>
        /// Assembly-CSharp-Editor
        /// </summary>
        public static Assembly CS_Editor
        {
            get
            {
                if (cs_Editor == null) cs_Editor = Get("Assembly-CSharp-Editor");
                return cs_Editor;
            }
        }


        public static string CS_AsmPath
        {
            get
            {
                if (string.IsNullOrEmpty(cs_AsmPath))
                {
                    cs_AsmPath = Path.GetFullPath("./Library/ScriptAssemblies/Assembly-CSharp.dll");
                }
                return cs_AsmPath;
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static Assembly Get<T>()
        {
            var asm = Assembly.GetAssembly(typeof(T));
            return asm;
        }

        private static AsmDic GetDic()
        {
            var dic = new AsmDic();
            var asms = AppDomain.CurrentDomain.GetAssemblies();
            int length = asms.Length;
            for (int i = 0; i < length; i++)
            {
                var asm = asms[i];
                var asmName = asm.GetName();
                dic.Add(asmName.Name, asm);
            }
            return dic;
        }


        private static Assembly Get(string asmName)
        {
            if (string.IsNullOrEmpty(asmName)) return null;
            return (Dic.ContainsKey(asmName)) ? Dic[asmName] : null;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static List<string> GetTypes(Assembly asm)
        {
            if (asm == null) return null;
            var types = asm.GetTypes();
            if (types == null || types.Length < 1) return null;
            var names = new List<string>();
            int length = types.Length;
            for (int i = 0; i < length; i++)
            {
                var type = types[i];
                names.Add(type.FullName);
            }
            return names;
        }


        public static List<string> GetSubTypes(Assembly asm, Type super)
        {
            if (asm == null || super == null) return null;
            var types = asm.GetTypes();
            if (types == null || types.Length < 1) return null;
            var names = new List<string>();
            int length = types.Length;
            for (int i = 0; i < length; i++)
            {
                var type = types[i];
                if (type.IsSubclassOf(super))
                {
                    names.Add(type.FullName);
                }
            }
            return names;
        }

        [MenuItem(Menu + "显示所有类型", false, Pri)]
        [MenuItem(AMenu + "显示所有类型", false, Pri)]
        public static void ShowAllTypes()
        {
            var names = GetTypes(CS);
            StrWin.Open(names);
        }

        [MenuItem(Menu + "显示继承Mono的类型", false, Pri + 1)]
        [MenuItem(AMenu + "显示继承Mono的类型", false, Pri + 1)]
        public static void ShowMonoTypes()
        {
            var type = typeof(MonoBehaviour);
            var names = GetSubTypes(CS, type);
            StrWin.Open(names);
        }

        [MenuItem(Menu + "显示继承ScriptableObject的类型", false, Pri + 2)]
        [MenuItem(AMenu + "显示继承ScriptableObject的类型", false, Pri + 2)]
        public static void ShowScriptableTypes()
        {
            var type = typeof(ScriptableObject);
            var names = GetSubTypes(CS, type);
            StrWin.Open(names);
        }


        #endregion
    }
}