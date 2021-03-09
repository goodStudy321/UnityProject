/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 21:34:49
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 包详细清单文件
    /// </summary>
    public class PackDetailMenifest
    {
        #region 字段
        [XmlArrayItem("it")]
        public List<eAssetInfo> infos = new List<eAssetInfo>();
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
        /// <summary>
        /// 获取字典,k:资源名(小写),v:eAssetInfo
        /// </summary>
        /// <returns></returns>
        public Dictionary<string, eAssetInfo> GetDic()
        {
            if (infos == null || infos.Count < 1) return null;
            var dic = new Dictionary<string, eAssetInfo>();
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                var path = info.path;
                if (string.IsNullOrEmpty(path)) continue;
                var name = Path.GetFileName(path);
                if (dic.ContainsKey(name)) continue;
                name = name.ToLower();
                dic.Add(name, info);
            }
            return dic;
        }
        #endregion
    }
}