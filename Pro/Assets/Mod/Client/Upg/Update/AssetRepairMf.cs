//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/6/4 12:06:57
// 修复清单内容,判断本地持久化资源是否在清单字典中存在
// 如果存在则设置其为校验完成
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AssetRepairMf
    /// </summary>
    public class AssetRepairMf
    {
        #region 字段
        private int dirLen = 0;

        /// <summary>
        /// 已存在文件列表
        /// </summary>
        public List<string> files = null;

        /// <summary>
        /// 清单字典
        /// </summary>
        public Dictionary<string, Md5Info> dic = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public event Action complete = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Start(object o)
        {
            string file = null;
            dirLen = AssetPath.Persistent.Length + 1;
            while (true)
            {
                file = null;
                lock (files)
                {
                    if (files.Count < 1) break;
                    var last = files.Count - 1;
                    file = files[last];
                    files.RemoveAt(last);
                }

                var key = file.Substring(dirLen);
                key = key.Replace('\\', '/');
                if (dic.ContainsKey(key))
                {
                    var info = dic[key];
                    var fileMd5 = Md5Crypto.GenFile(file);
                    if (fileMd5 == info.MD5)
                    {
                        info.Op = (int)AssetOp.Verify;
                    }
                    else
                    {
                        AssetRepair.Instance.AddRepair(info);
                    }
                }
            }

            Complete();
        }

        private void Complete()
        {
            if (complete != null) complete();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void StartUp()
        {
            while (!ThreadPool.QueueUserWorkItem(Start))
            {
                Thread.Sleep(10);
            }
        }
        #endregion
    }
}