#if UNITY_EDITOR
/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/10 0:22:21
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 资源加载监听
    /// </summary>
    [Serializable]
    public class AssetLoadLsnr
    {
        #region 字段
        public const string path = "../AssetLoadLsnr/AssetLoadLsnr.xml";

        public string filePath = null;

        /// <summary>
        /// k:包名
        /// </summary>
        private Dictionary<string, AssetLoadInfo> dic = new Dictionary<string, AssetLoadInfo>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetLoadLsnr()
        {

        }

        public AssetLoadLsnr(string path)
        {
            filePath = path;
        }
        #endregion

        #region 私有方法
        private int GetLv()
        {
            var data = User.instance.MapData;
            if (data == null) return 0;
            return data.Level;
        }
        #endregion

        #region 保护方法
        public void Add(string name, string path)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (dic.ContainsKey(name)) return;
            var lv = GetLv();
            var info = new AssetLoadInfo();
            info.Lv = lv;
            info.path = path;
            dic.Add(name, info);
        }

        public bool Contains(string name)
        {
            return dic.ContainsKey(name);
        }

        public void Save()
        {
            if (filePath == null) filePath = path;
            Save(filePath);
        }


        public void Save(string path)
        {
            var infos = new List<AssetLoadInfo>();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                infos.Add(em.Current.Value);
            }
            infos.Sort();
            FileTool.CheckDir(path);
            XmlTool.Serializer<List<AssetLoadInfo>>(path, infos);
            Debug.LogWarningFormat("Loong,保存监听资源文件到:{0}", path);
        }
        #endregion

        #region 公开方法
        public void Init()
        {
            MonoEvent.onDestroy += Save;
        }

        public void Clear()
        {
            dic.Clear();
        }

        #endregion
    }
}
#endif