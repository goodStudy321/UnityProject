//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 22:23:10
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Random = UnityEngine.Random;
    /// <summary>
    /// CodeUtil
    /// </summary>
    public static class CodeUtil
    {
        #region 字段

        private static List<char> splits = new List<char>
        {
            '_',',','|','-','#','*','%'
        };

        private static List<string> oprs = new List<string>
        {
            "+","-","*","/"
        };

        private static HashSet<string> keys = new HashSet<string>
        {
            "class","lock","system","void","staic","new","string",
            "byte","sbyte","bool","boolean","short","ushort","int16","uint16",
            "int","int32","uint32","long","int64","uint64","double","float",
            "privete", "internal","protected","public","set","get","value","retrun",
            "path","file","directory",
            "using","namespace",
            "start","awake","update","lateupdate","fixedupdate","ongui","ondestroy",
            "ondisable","onenable","onbecamevisible","onbecameinvisible",
            "download","packdl","npc","unit",
            "png","jpg","tga","ab",
        };
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

        public static void Init()
        {
            var output = ABTool.Data.Output;
            output = Path.Combine(output, "table");
            if (!Directory.Exists(output)) return;
            var files = Directory.GetFiles(output, "*", SearchOption.AllDirectories);
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var name = Path.GetFileNameWithoutExtension(file);
                AddKey(name);
            }
        }

        public static void AddKey(string k)
        {
            if (string.IsNullOrEmpty(k)) return;
            k = k.ToLower();
            if (keys.Contains(k)) return;
            keys.Add(k);
        }

        public static void SetTap(StringBuilder sb, int tap)
        {
            for (int i = 0; i < tap; i++)
            {
                sb.Append("\t");
            }
        }

        public static void SetAccessType(StringBuilder sb, CSAccessType type)
        {
            sb.Append(type.ToString().ToLower());
        }

        /// <summary>
        /// 随机获取属性类型
        /// </summary>
        /// <returns></returns>
        public static CSPropType GetRandomPropType()
        {
            var idx = Random.Range(0, 3);
            idx = Random.Range(0, 3);
            if (idx == 0) return CSPropType.All;
            if (idx == 1) return CSPropType.Get;
            return CSPropType.Set;

        }

        /// <summary>
        /// 随机获取访问级别
        /// </summary>
        /// <returns></returns>
        public static CSAccessType GetRandomAccessType()
        {
            var idx = Random.Range(0, 4);
            idx = Random.Range(0, 4);
            if (idx == 0) return CSAccessType.Internal;
            if (idx == 1) return CSAccessType.Private;
            if (idx == 2) return CSAccessType.Protected;
            return CSAccessType.Public;
        }

        /// <summary>
        /// 随机获取类型访问级别
        /// </summary>
        /// <returns></returns>
        public static CSAccessType GetRandomClassAccessType()
        {
            var idx = Random.Range(0, 4);
            idx = Random.Range(0, 4);
            return ((idx > 1) ? CSAccessType.Public : CSAccessType.Internal);
        }

        /// <summary>
        /// 随机获取是否列表
        /// </summary>
        /// <returns></returns>
        public static bool GetRandomIsList()
        {
            var idx = Random.Range(0, 2);
            idx = Random.Range(0, 2);
            return idx > 0;
        }

        /// <summary>
        /// 读取文件内的所有行并返回字符串列表
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <returns></returns>
        public static List<string> GetStrs(string path)
        {
            var set = GetDic(path);
            if (set == null) return null;
            var lst = new List<string>();
            var em = set.GetEnumerator();
            while (em.MoveNext())
            {
                lst.Add(em.Current.Key);
            }
            return lst;
        }

        public static Dictionary<string, string> GetDic(string path, Dictionary<string, string> dic = null)
        {
            if (!File.Exists(path)) return null;
            var name = Path.GetFileName(path);
            if (dic == null) dic = new Dictionary<string, string>();
            using (var fs = File.OpenRead(path))
            {
                using (var reader = new StreamReader(fs))
                {
                    string line = null;
                    while ((line = reader.ReadLine()) != null)
                    {
                        line = line.Trim();
                        if (string.IsNullOrEmpty(line)) continue;
                        var key = line.ToLower();
                        if (keys.Contains(key))
                        {
                            iTrace.Error("Loong", "不允许关键字:{0}, in:{1}", line, path);
                            continue;
                        }
                        if (dic.ContainsKey(key))
                        {
                            iTrace.Error("Loong", "重复名称:{0}, 在:{1}和{2}之间", line, dic[key], name);
                        }
                        else
                        {
                            dic.Add(key, name);
                        }
                    }
                }
            }
            return dic;
        }


        /// <summary>
        /// 获取字符串列表中的随机条目,并从列表中移除条目
        /// </summary>
        /// <param name="strs"></param>
        /// <returns></returns>
        public static string GetRandomStr(List<string> strs)
        {
            if (strs == null || strs.Count < 1) return "Cfg_" + DateTime.Now.Ticks;
            var idx = Random.Range(0, strs.Count);
            idx = Random.Range(0, strs.Count);
            var str = strs[idx];
            ListTool.Remove<string>(strs, idx);
            return str;
        }

        /// <summary>
        /// 获取随机基类,可返回空值
        /// </summary>
        /// <param name="baseClasses"></param>
        /// <returns></returns>
        public static string GetRandomBase(List<string> baseClasses)
        {
            var idx = Random.Range(-1, baseClasses.Count);
            if (idx < 0) return null;
            return baseClasses[idx];
        }

        /// <summary>
        /// 获取随机算数
        /// </summary>
        /// <returns></returns>
        public static string GetRandomOpr()
        {
            return GetRandomIt(oprs);
        }

        public static char GetRandomSplit()
        {
            return GetRandomIt(splits);
        }

        public static T GetRandomIt<T>(List<T> lst, bool remove = false)
        {
            var i = Random.Range(0, lst.Count);
            i = Random.Range(0, lst.Count);
            var it = lst[i];
            if (remove) ListTool.Remove<T>(lst, i);
            return it;
        }

        public static string GetRandomFloat()
        {
            var val = Random.Range(Int16.MinValue, Int16.MaxValue);
            //var len = Random.Range(0, 8);
            //var fmt = "{0:N" + len + "}";
            //return string.Format(fmt, val, len);
            return val + "f";
        }

        public static string GetRandom0_1()
        {
            var val = Random.Range(0f, 1f);
            return val + "f";
        }

        public static string GetRandomSigned()
        {
            return Random.Range(Int16.MinValue, Int16.MaxValue).ToString();
        }

        public static string GetRandomUnsign()
        {
            return Random.Range(UInt16.MinValue, UInt16.MaxValue).ToString();
        }

        public static string GetRandomChar()
        {
            var i = Random.Range(97, 123);
            var c = (char)i;
            return c.ToString();
        }


        public static string GetRandomDefault(CSType type)
        {

            switch (type)
            {
                case CSType.Bool:
                    return (Random.Range(0, 4) > 1).ToString().ToLower();
                case CSType.Byte:
                    return Random.Range(byte.MinValue, byte.MaxValue).ToString();
                case CSType.SByte:
                    return Random.Range(SByte.MinValue, SByte.MaxValue).ToString();
                case CSType.Char:
                    return string.Format("'{0}\'", GetRandomChar());
                case CSType.Int16:
                case CSType.Int32:
                case CSType.Int64:
                    return GetRandomSigned();
                case CSType.UInt16:
                case CSType.UInt32:
                case CSType.UInt64:
                    return GetRandomUnsign();
                case CSType.Float:
                case CSType.Double:
                    return GetRandomFloat();
                case CSType.String:
                    return string.Format("\"{0}\"", DateTime.Now.Ticks);
                case CSType.Vector2:
                    var x2 = GetRandomFloat();
                    var y2 = GetRandomFloat();
                    return string.Format("new Vector2({0}, {1})", x2, y2);
                case CSType.Vector3:
                    var x3 = GetRandomFloat();
                    var y3 = GetRandomFloat();
                    var z3 = GetRandomFloat();
                    return string.Format("new Vector3({0}, {1}, {2})", x3, y3, z3);
                case CSType.Vector4:
                    var x4 = GetRandomFloat();
                    var y4 = GetRandomFloat();
                    var z4 = GetRandomFloat();
                    var w4 = GetRandomFloat();
                    return string.Format("new Vector4({0}, {1}, {2}, {3})", x4, y4, z4, w4);
                case CSType.Color:
                    var r = GetRandom0_1();
                    var g = GetRandom0_1();
                    var b = GetRandom0_1();
                    var a = GetRandom0_1();
                    return string.Format("new Color({0}, {1}, {2}, {3})", r, g, b, a);
                default:
                    return "";
            }
        }

        public static string GetRandomDefault(string type)
        {
            var info = CSTypeMgr.Get(type);
            if (info == null) return null;
            return GetRandomDefault(info.Type);
        }
        #endregion
    }
}