/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 19:42:14
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
    /// 包清单文件
    /// </summary>
    /// 
    public class PackManifest
    {
        #region 字段
        [XmlArrayItem("pack")]
        public List<AssetPack> packs = new List<AssetPack>();
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
        public void Sort()
        {
            packs.Sort();
            int length = packs.Count;
            for (int i = 0; i < length; i++)
            {
                var pack = packs[i];
                pack.Sort();
            }
        }

        public bool Valid()
        {
            return IsValid(packs);
        }


        public static bool IsValid(List<AssetPack> packs)
        {
            int length = packs.Count;
            bool valid = true;
            for (int i = 0; i < length; i++)
            {
                var pack = packs[i];
                if (pack.Valid()) continue;
                valid = false;
            }
            return valid;
        }

        #endregion
    }
}