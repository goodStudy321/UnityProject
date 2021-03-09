using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public static class PreprocessCmdUtil
    {
        /// <summary>
        /// 预处理指令列表
        /// </summary>
        private static List<string> symbols = null;

        /// <summary>
        /// 获取当前平台的预处理指令
        /// </summary>
        /// <returns></returns>
        public static List<string> GetSymbols()
        {
            var group = BuildSettingsUtil.GetGroup();
            return GetSymbols(group);
        }

        /// <summary>
        /// 获取指定平台的预处理指令列表
        /// </summary>
        /// <param name="group"></param>
        /// <returns></returns>
        public static List<string> GetSymbols(BuildTargetGroup group)
        {
            var strs = PlayerSettings.GetScriptingDefineSymbolsForGroup(group);
            var symbols = strs.Split(';');
            var lst = new List<string>();
            if (symbols == null || symbols.Length < 1) return lst;
            int length = symbols.Length;
            for (int i = 0; i < length; i++)
            {
                string str = symbols[i];
                if (string.IsNullOrEmpty(str)) continue;
                lst.Add(str);
            }
            return lst;
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public static void Init()
        {
            symbols = GetSymbols();
        }

        /// <summary>
        /// 添加符号
        /// </summary>
        /// <param name="symbol"></param>
        public static void Add(string symbol)
        {
            if (string.IsNullOrEmpty(symbol)) return;
            if (symbols.Contains(symbol)) return;
            symbols.Add(symbol);
        }

        /// <summary>
        /// 添加符号
        /// </summary>
        /// <param name="arr">符号数组</param>
        public static void Add(string[] arr)
        {
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                string sym = arr[i];
                Add(sym);
            }
        }

        /// <summary>
        /// 添加符号
        /// </summary>
        /// <param name="lst">符号列表</param>
        public static void Add(List<string> lst)
        {
            if (lst == null) return;
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                string sym = lst[i];
                Add(sym);
            }
        }

        /// <summary>
        /// 添加符号,将符号数组中中的其它符号移除
        /// </summary>
        /// <param name="arr">符号数组</param>
        /// <param name="symbol">符号</param>
        public static void Switch(string[] arr, string symbol)
        {
            if (string.IsNullOrEmpty(symbol)) return;
            Add(symbol);
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                string sym = arr[i];
                if (sym != symbol)
                {
                    Remove(sym);
                }
            }
        }

        /// <summary>
        /// 添加符号,将符号数组中中的其它符号移除
        /// </summary>
        /// <param name="lst">符号数组</param>
        /// <param name="symbol">符号</param>
        public static void Switch(List<string> lst, string symbol)
        {
            if (string.IsNullOrEmpty(symbol)) return;
            Add(symbol);
            if (lst == null) return;
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                string sym = lst[i];
                if (sym != symbol)
                {
                    Remove(sym);
                }
            }
        }

        /// <summary>
        /// 添加符号,将符号字典中的其它符号(键值)移除
        /// </summary>
        /// <param name="dic"></param>
        /// <param name="symbol"></param>
        public static void Switch(Dictionary<string, string> dic, string symbol)
        {
            var em = dic.GetEnumerator();
            Add(symbol);
            while (em.MoveNext())
            {
                var key = em.Current.Key;
                if (symbol != key)
                {
                    Remove(key);
                }
            }
        }

        /// <summary>
        /// 移除符号
        /// </summary>
        /// <param name="symbol"></param>
        public static void Remove(string symbol)
        {
            if (string.IsNullOrEmpty(symbol)) return;
            if (!symbols.Contains(symbol)) return;
            symbols.Remove(symbol);
        }

        /// <summary>
        /// 移除符号
        /// </summary>
        /// <param name="arr">符号数组</param>
        public static void Remove(string[] arr)
        {
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var sym = arr[i];
                Remove(sym);
            }
        }

        /// <summary>
        /// 移除符号
        /// </summary>
        /// <param name="lst">符号列表</param>
        public static void Remove(List<string> lst)
        {
            if (lst == null) return;
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var sym = lst[i];
                Remove(sym);
            }
        }

        /// <summary>
        /// 处理符号
        /// </summary>
        /// <param name="add">true:添加,反之移除</param>
        /// <param name="symbol">符号</param>
        public static void Mutex(bool add, string symbol)
        {
            if (add)
            {
                Add(symbol);
            }
            else
            {
                Remove(symbol);
            }
        }

        /// <summary>
        /// 应用当前平台的预处理指令
        /// </summary>
        public static void Apply()
        {
            var group = BuildSettingsUtil.GetGroup();
            Apply(symbols, group);
        }

        /// <summary>
        /// 应用指令
        /// </summary>
        /// <param name="lst">指令列表</param>
        /// <param name="group">平台组</param>
        public static void Apply(List<string> lst, BuildTargetGroup group)
        {
            if (lst == null || lst.Count == 0)
            {
                PlayerSettings.SetScriptingDefineSymbolsForGroup(group, "");
                UIEditTip.Log("已清空指令!"); return;
            }
            int count = lst.Count;
            var sb = new StringBuilder();
            int last = count - 1;
            for (int i = 0; i < count; i++)
            {
                string str = lst[i];
                sb.Append(str);
                if (i != last)
                {
                    sb.Append(";");
                }
            }

            PlayerSettings.SetScriptingDefineSymbolsForGroup(group, sb.ToString());
            UIEditTip.Warning("应用成功!");
        }


    }
}

