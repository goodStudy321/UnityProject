/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.6 20:09:23
 ============================================================================*/

using System.IO;
using System.Text;
using UnityEngine;
using System.Xml.Serialization;

namespace Loong.Game
{

    /// <summary>
    /// XML工具
    /// </summary>
    public static class XmlTool
    {

        /// <summary>
        /// 通过WWW加载资源后在内存中反序列化
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="path">路径</param>
        public static T DeserializerByWWWLoad<T>(string path) where T : class
        {
            byte[] arr = WwwTool.LoadSync(path);
            if (arr == null) return null;
            if (arr.Length == 0) return null;
            T t = null;
            using (var ms = new MemoryStream(arr))
            {
                var ser = new XmlSerializer(typeof(T));
                t = ser.Deserialize(ms) as T;
            }
            return t;
        }

        /// <summary>
        /// XML序列化
        /// </summary>
        /// <typeparam name="T">序列化对象类型</typeparam>
        /// <param name="path">序列化路径</param>
        /// <param name="obj">序列化对象</param>
        public static void Serializer<T>(string path, T obj) where T : class
        {
            if (obj == null) return;
            using (var sw = new StreamWriter(path, false, Encoding.UTF8))
            {
                var ser = new XmlSerializer(typeof(T));
                ser.Serialize(sw, obj);
            }
        }

        /// <summary>
        /// XML反序列化
        /// </summary>
        /// <typeparam name="T">序列化对象类型</typeparam>
        /// <param name="path">序列化路径</param>
        /// <returns>返回对象</returns>
        public static T Deserializer<T>(string path) where T : class
        {
            if (!File.Exists(path)) return null;
            using (var fs = new FileStream(path, FileMode.Open))
            {
                var ser = new XmlSerializer(typeof(T));
                return ser.Deserialize(fs) as T;
            }
        }
    }
}