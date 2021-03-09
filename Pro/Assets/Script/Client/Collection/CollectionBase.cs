using System;
using UnityEngine;
using Phantom.Protocal;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        573e1829-44a4-4a85-8af3-073af25cd2e9
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 15:07:18
    /// BG:采集物基类
    /// </summary>
    public abstract class CollectionBase : IDisposable
    {
        #region 字段
        private long uid = -1;

        private GameObject go = null;

        private CollectionInfo info = null;

        #endregion

        #region 属性
        /// <summary>
        /// 唯一ID
        /// </summary>
        public long UID
        {
            get { return uid; }
            set { uid = value; }
        }

        /// <summary>
        /// 游戏对象
        /// </summary>
        public GameObject Go
        {
            get { return go; }
            set { go = value; }
        }

        /// <summary>
        /// 配置信息
        /// </summary>
        public CollectionInfo Info
        {
            get { return info; }
            set { info = value; }
        }


        #endregion

        #region 构造方法
        public CollectionBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 请求开始采集
        /// </summary>
        public virtual void ReqBegCollect()
        {

        }

        /// <summary>
        /// 响应开始采集
        /// </summary>
        public virtual void RespBegCollect(m_collect_start_toc resp)
        {

        }

        /// <summary>
        /// 请求停止采集
        /// </summary>
        public virtual void ReqStopCollect()
        {

        }

        /// <summary>
        /// 响应停止采集
        /// </summary>
        /// <param name="resp"></param>
        public virtual void RespStopCollect(m_collect_stop_toc resp)
        {

        }

        /// <summary>
        /// 响应结束采集
        /// </summary>
        /// <param name="resp"></param>
        public virtual void RespEndCollect(m_collect_succ_toc resp)
        {

        }

        /// <summary>
        /// 初始化
        /// </summary>
        public abstract void Initilize();

        /// <summary>
        /// 更新
        /// </summary>
        public abstract void Update();

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {
            Go.name = Info.model;
            GbjPool.Instance.Add(Go);
            ObjPool.Instance.Add(this);
            Go = null;
            Info = null;
            UID = -1;
        }
        #endregion
    }
}