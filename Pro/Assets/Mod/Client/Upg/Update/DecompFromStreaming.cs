//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/21 23:16:16
// 从流目录解压资源
//=============================================================================

using System;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    public abstract class DecompFromStreaming
    {
        #region 字段
        protected DecompBase decomp = null;

        #endregion

        #region 属性
        public List<Md5Info> infos = null;

        public int count = 0;

        public long guid = 0L;
        #endregion

        #region 委托事件
        /// <summary>
        /// 结束事件,true:成功,false:失败
        /// </summary>
        public event Action<DecompFromStreaming, bool> CompleteEvent;
        #endregion

        #region 构造方法
        public DecompFromStreaming()
        {

        }

        public DecompFromStreaming(DecompBase decomp)
        {
            this.decomp = decomp;
            guid = GuidTool.GenDateLong();
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected abstract bool Decomped(Md5Info info);
        #endregion

        #region 公开方法
        public void Start(object o)
        {
            Decomp();
        }

        public void Complete(bool suc)
        {
            if (CompleteEvent != null) CompleteEvent(this, suc);
        }

        public bool Decomp()
        {
            bool suc = true;
            Md5Info info = null;
            while (true)
            {
                lock (infos)
                {
                    if (infos.Count < 1) break;
                    int last = infos.Count - 1;
                    info = infos[last];
                    infos.RemoveAt(last);
                }
                suc = Decomped(info);
                Thread.Sleep(1);
                ++count;
                if (suc) continue;
                break;
            }
            if (App.IsDebug)
            {
                Debug.LogWarningFormat("Loong decomp end {0} {1}", guid, count);
            }
            Complete(suc);
            return suc;
        }
        #endregion
    }
}