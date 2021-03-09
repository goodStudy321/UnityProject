/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/11/25 19:50:15
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// JsonUtil
    /// </summary>
    public static class JsonUtil
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
        public static void Save<T>(string path, T obj, bool pretty = false) where T : class
        {
            if (obj == null) return;
            using (var sw = new StreamWriter(path, false, Encoding.UTF8))
            {
                var str = JsonUtility.ToJson(obj, pretty);
                sw.Write(str);
            }
        }


        public static T Read<T>(string path) where T : class
        {
            if (!File.Exists(path)) return null;
            T t = null;
            using (var sr = new StreamReader(path))
            {
                var str = sr.ReadToEnd();
                t = JsonUtility.FromJson<T>(str);
            }
            return t;
        }
        #endregion
    }
}