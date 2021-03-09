using System;
using Loong.Game;
using System.Reflection;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:资源处理器字典
    /// </summary>
    [Serializable]
    public class AssetProcessorDictionary : SerializableDictionary<string, bool>
    {
        /// <summary>
        /// 显式构造函数
        /// </summary>
        public AssetProcessorDictionary()
        {
            Type type = typeof(Suffix);
            FieldInfo[] fields = type.GetFields(BindingFlags.Public | BindingFlags.Static);
            if (fields == null || fields.Length == 0)
            { iTrace.Error("Loong", "没有查找到Suffix的字段信息"); return; }
            int length = fields.Length;
            for (int i = 0; i < length; i++)
            {
                string key = fields[i].GetValue(null) as string;
                if (!CheckSuffix(key)) continue;
                this.Add(key, true);
            }
        }

        /// <summary>
        /// 检查后缀有效性
        /// </summary>
        /// <param name="suffix">后缀</param>
        /// <returns></returns>
        public bool CheckSuffix(string suffix)
        {
            if (string.IsNullOrEmpty(suffix)) return false;
            if (suffix == Suffix.None) return false;
            if (suffix == Suffix.CS) return false;
            if (suffix == Suffix.Js) return false;
            if (suffix == Suffix.Lua) return false;
            if (suffix == Suffix.Zip) return false;
            if (suffix == Suffix.AB) return false;
            if (suffix == Suffix.Meta) return false;
            if (suffix == Suffix.Manifest) return false;
            if (suffix == ".dll") return false;
            return true;
        }
    }
}
