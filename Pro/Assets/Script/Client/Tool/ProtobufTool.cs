using System;
using ProtoBuf;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        db530696-195c-4bf2-a6d7-85fd8ed2128b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/3/17 10:33:06
    /// BG:Protobuf工具
    /// </summary>
    public static class ProtobufTool
    {
        #region 字段
        private static MemoryStream serializeStream = new MemoryStream();

        private static MemoryStream deserializeStream = new MemoryStream();
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static ProtobufTool()
        {
            if (Application.isPlaying) MonoEvent.onDestroy += Dispose;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

#if UNITY_EDITOR
        /// <summary>
        /// 编辑器下通过类型实例序列化获取字节
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="t">实例</param>
        /// <returns></returns>
        public static byte[] SerializeEditor<T>(T t) where T : class, IExtensible
        {
            serializeStream = new MemoryStream();
            return Serialize(t);
        }
#endif


        /// <summary>
        /// 通过类型实例序列化获取字节
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="t">实例</param>
        /// <returns></returns>
        public static byte[] Serialize<T>(T t) where T : class, IExtensible
        {
            if (t == null) return null;
            byte[] buffer = null;
            serializeStream.SetLength(0);
            Serializer.Serialize<T>(serializeStream, t);
            serializeStream.Position = 0;
            int length = (int)serializeStream.Length;
            buffer = new byte[length];
            serializeStream.Read(buffer, 0, length);
            return buffer;
        }


        /// <summary>
        /// 通过字节数组反序列化获取类型实例
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="arr">字节数组</param>
        /// <returns></returns>
        public static T Deserialize<T>(byte[] arr) where T : class, IExtensible
        {
            if (arr == null) return null;
            if (arr.Length == 0) return null;
            T t = null;
            deserializeStream.SetLength(0);
            deserializeStream.Write(arr, 0, arr.Length);
            deserializeStream.Position = 0;
            t = Serializer.Deserialize<T>(deserializeStream);
            return t;
        }

        /// <summary>
        /// 通过字节数组反序列化获取类型实例
        /// </summary>
        /// <typeparam name="T">泛型</typeparam>
        /// <param name="type">指定泛型的类型</param>
        /// <param name="arr"></param>
        /// <returns></returns>
        public static object Deserialize(Type type, byte[] arr)
        {
            if (type == null) return null;
            if (arr == null) return null;
            if (arr.Length == 0) return null;
            object obj = null;
            deserializeStream.SetLength(0);
            deserializeStream.Write(arr, 0, arr.Length);
            deserializeStream.Position = 0;
            obj = Serializer.NonGeneric.Deserialize(type, deserializeStream);
            return obj;
        }

        /// <summary>
        /// 通过配置文件加载
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="path"></param>
        /// <returns></returns>
        public static T Deserialize<T>(string path) where T : class, IExtensible
        {
            byte[] arr = WwwTool.LoadSync(path);
            if (arr == null) return null;
            if (arr.Length == 0) return null;
            T t = null;
            using (MemoryStream ms = new MemoryStream(arr))
            {
                t = Serializer.Deserialize<T>(ms);
            }
            return t;
        }


        public static void Dispose()
        {
            serializeStream.Dispose();
            deserializeStream.Dispose();
        }
        #endregion
    }
}