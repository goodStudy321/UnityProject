using System;
using System.Text;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.5
    /// BG:WWW工具
    /// </summary>
    public static class WwwTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 加载文件
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="cb">回调</param>
        /// <returns></returns>
        private static IEnumerator YieldLoad(string path, Action<byte[]> cb)
        {
            if (cb == null) yield break;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    cb(request.downloadHandler.data);
                }
                else
                {
                    iTrace.Error("Loong", "Load:{0},err:{1}", path, err);
                    cb(null);
                }
            }
        }


        private static IEnumerator YieldUpload(string url, string data)
        {
            if (string.IsNullOrEmpty(url)) yield break;
            if (string.IsNullOrEmpty(data)) yield break;
            var buf = Encoding.UTF8.GetBytes(data);
            using (UnityWebRequest request = UnityWebRequest.Post(url, data))
            {
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    Debug.LogFormat("upload:{0}", data);
                }
                else
                {
                    Debug.LogFormat("upload data:{0} err:{1}", data, err);
                }
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 加载文件并返回字节数组
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        [NoToLua]
        public static byte[] LoadSync(string path)
        {
            if (string.IsNullOrEmpty(path)) return null;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                request.SendWebRequest();
                while (!request.isDone) { }
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    return request.downloadHandler.data;
                }
                Debug.LogErrorFormat("Loong,Load:{0},err:{1}", path, err);
                return null;
            }
        }

        /// <summary>
        /// 加载文件并返回字符串
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        [NoToLua]
        public static string LoadText(string path)
        {
            if (string.IsNullOrEmpty(path)) return null;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                var UWRAsynOp = request.SendWebRequest();
                while (!UWRAsynOp.isDone) { }
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    return request.downloadHandler.text;
                }
                Debug.LogErrorFormat("Loong,Load:{0},err:{1}", path, err);
                return null;
            }
        }

        /// <summary>
        /// 加载文件
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="cb">回调</param>
        [NoToLua]
        public static void LoadAsync(string path, Action<byte[]> cb)
        {
            if (string.IsNullOrEmpty(path)) return;
            MonoEvent.Start(YieldLoad(path, cb));
        }

        /// <summary>
        /// 上传数据
        /// </summary>
        /// <param name="url"></param>
        /// <param name="data"></param>
        public static void Upload(string url, string data)
        {
            if (string.IsNullOrEmpty(url)) return;
            if (string.IsNullOrEmpty(data)) return;
            MonoEvent.Start(YieldUpload(url, data));
        }


        public static UnityWebRequest Create(string url, string data)
        {
            return UnityWebRequest.Post(url, data);
        }
        #endregion
    }
}