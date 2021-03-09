using System;
using LuaInterface;
using Phantom.Protocal;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        20ae9a34-b63b-473c-8faa-ac363871518b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/18 21:36:39
    /// BG:错误码管理
    /// </summary>
    public static class ErrorCodeMgr
    {
        #region 字段
        private static Dictionary<int, p_ks> dic = new Dictionary<int, p_ks>();
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
        /// <param name="id">错误码ID</param>
        [NoToLua]
        public static void Add(int id, p_ks info)
        {
            if (info == null) return;
            if (dic.ContainsKey(id)) return;
            dic.Add(id, info);
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="id">错误码ID</param>
        [NoToLua]
        public static void Remove(int id)
        {
            if (dic.ContainsKey(id))
            {
                dic.Remove(id);
            }
        }
        /// <summary>
        /// 获取错误码信息
        /// </summary>
        /// <param name="id">错误码ID</param>
        /// <returns></returns>
        [NoToLua]
        public static p_ks Get(int id)
        {
            if (dic.ContainsKey(id)) return dic[id];
            return null;
        }

        /// <summary>
        /// 获取错误信息字符
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public static string GetError(int id)
        {
            if (dic.ContainsKey(id))
            {
                return dic[id].str;
            }
            return string.Format("无ID为:{0}的错误码", id);
        }

        public static void Error(string name, int id)
        {
            string err = GetError(id);
            UITip.Error(err);
            iTrace.Error(name, err);
        }

        /// <summary>
        /// 释放
        /// </summary>
        [NoToLua]
        public static void Dispose()
        {
            dic.Clear();
        }

        /// <summary>
        /// 加载配置
        /// </summary>
        [NoToLua]
        public static void Load()
        {
            string prefix = AssetPath.WwwCommen;
            string path = string.Format("{0}Proto/ErrorCode.bin", prefix);
            c_error_id errorCode = ProtobufTool.Deserialize<c_error_id>(path);

            if (errorCode == null || errorCode.id_list.Count == 0)
            {
                iTrace.Error("Loong", string.Format("错误码文件:{0}中没有任何内容,也有可能是解析错误", path));
                return;
            }
            int length = errorCode.id_list.Count;
            for (int i = 0; i < length; i++)
            {
                p_ks info = errorCode.id_list[i];
                Add(info.id, info);
            }
        }
        #endregion
    }
}