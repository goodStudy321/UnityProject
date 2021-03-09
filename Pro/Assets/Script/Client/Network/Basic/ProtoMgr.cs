using System;
using System.IO;
using UnityEngine;
using Phantom.Protocal;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.12.5
    /// BG:协议ID和类型的管理
    /// </summary>
    public static class ProtoMgr
    {
        #region 字段
        /// <summary>
        /// 协议命名空间前缀
        /// </summary>
        public const string PrefixNameSpace = "Phantom.Protocal";
        /// <summary>
        /// 键为协议ID 值为类型的字典
        /// </summary>
        private static Dictionary<int, Type> idToTypeDic = new Dictionary<int, Type>();

        /// <summary>
        /// 键为类型 值为协议ID的字典
        /// </summary>
        private static Dictionary<Type, int> typeToIDDic = new Dictionary<Type, int>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 添加
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="id">协议ID</param>
        public static void Add<T>(int id)
        {
            Add(id, typeof(T));
        }
        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="id">协议ID</param>
        /// <param name="type">类型</param>
        public static void Add(int id, Type type)
        {
            if (type == null) return;
            if (idToTypeDic.ContainsKey(id)) return;
            idToTypeDic.Add(id, type);
            typeToIDDic.Add(type, id);
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="id">协议ID</param>
        /// <param name="typeName">类型</param>
        public static void Add(int id, string typeName)
        {
            if (string.IsNullOrEmpty(typeName)) return;
            Type type = Type.GetType(typeName);
            if (type == null)
            {
#if UNITY_EDITOR
                iTrace.Error("Loong", string.Format("未发现ID:{0}的对应类型:{1},可能的原因是协议类型文件(Protos.bin)和协议文件(proto.cs)的类型不一致;更新并重新生成协议文件,若仍然报错,则需确定后端是否提交协议结构文件", id, typeName));
#else
                iTrace.Error("Loong", string.Format("未发现ID:{0}的对应类型:{1}", id, typeName));
#endif
            }
            else
            {
                Add(id, type);
            }
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="id">协议ID</param>
        public static void Remove(int id)
        {
            if (!idToTypeDic.ContainsKey(id)) return;
            Type type = idToTypeDic[id];
            idToTypeDic.Remove(id);
            typeToIDDic.Remove(type);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        public static void Remove<T>()
        {
            Remove(typeof(T));
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="type">类型</param>
        public static void Remove(Type type)
        {
            if (type == null) return;
            if (!typeToIDDic.ContainsKey(type)) return;
            int id = typeToIDDic[type];
            typeToIDDic.Remove(type);
            idToTypeDic.Remove(id);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="typeName">类型名称</param>
        public static void Remove(string typeName)
        {
            Type type = Type.GetType(typeName);
            Remove(type);
        }

        /// <summary>
        /// 获取类型
        /// </summary>
        /// <param name="id">协议ID</param>
        /// <returns></returns>
        public static Type Get(ushort id)
        {
            if (idToTypeDic.ContainsKey(id))
            {
                return idToTypeDic[id];
            }
            return null;
        }

        /// <summary>
        /// 获取协议ID
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <returns></returns>
        public static int Get<T>() where T : class
        {
            return Get(typeof(T));
        }

        /// <summary>
        /// 获取协议ID
        /// </summary>
        /// <param name="type">类型</param>
        /// <returns></returns>
        public static int Get(Type type)
        {
            if (type == null) return 0;
            if (typeToIDDic.ContainsKey(type))
            {
                return typeToIDDic[type];
            }
            return 0;
        }

        /// <summary>
        /// 获取协议ID
        /// </summary>
        /// <param name="typeName">类型名称</param>
        /// <returns></returns>
        public static int Get(string typeName)
        {
            if (string.IsNullOrEmpty(typeName)) return 0;
            Type type = Type.GetType(typeName);
            return Get(type);
        }

        /// <summary>
        /// 加载配置
        /// </summary>
        public static void Load()
        {
            string prefix = AssetPath.WwwCommen;
            string path = string.Format("{0}Proto/Protos.bin", prefix);
            c_proto_id protos = ProtobufTool.Deserialize<c_proto_id>(path);
            if (protos == null || protos.id_list.Count == 0)
            {
                iTrace.Error("Loong", string.Format("协议映射文件:{0},中没有任何内容,也有可能是解析错误", path));
                return;
            }
            int length = protos.id_list.Count;
            for (int i = 0; i < length; i++)
            {
                p_ks info = protos.id_list[i];
                if (string.IsNullOrEmpty(info.str)) continue;
                string typeName = string.Format("{0}.{1}", PrefixNameSpace, info.str);
                Add(info.id, typeName);
            }
        }

        public static void Dispose()
        {
            idToTypeDic.Clear();
            typeToIDDic.Clear();
        }
        #endregion
    }
}