/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/9/2 00:00:00
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
namespace Loong.Game
{

    /// <summary>
    /// 音效有参数委托处理
    /// </summary>
    public class DelAudioParam : DelObj<AudioClip>
    {
        #region 字段
        private string name = "";
        private bool persist = false;
        #endregion

        #region 属性
        /// <summary>
        /// 音效名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
        }


        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }

        #endregion

        #region 构造方法
        public DelAudioParam()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override AudioClip Get(Object obj)
        {
            AudioClip clip = obj as AudioClip;
            return clip;
        }

        protected override void Execute(AudioClip t)
        {
            AudioPool.Instance.Add(name, t);
            if (persist)
            {
                AssetMgr.Instance.SetPersist(name);
            }
        }
        #endregion

        #region 公开方法
        public override void Dispose()
        {
            name = "";
            persist = false;
        }
        #endregion
    }
}