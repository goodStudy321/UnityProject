/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/9/2 00:00:00
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// 音效淡入淡出委托处理
    /// </summary>
    public class DelAudioCrossfade : DelAudioParam
    {
        #region 字段
        private float volume = 1;
        private float duration = 1;
        private Action<AudioClip, float, float> crossFade = null;
        #endregion
        #region 属性
        public float Volume
        {
            get { return volume; }
            set { volume = value; }
        }

        public float Duragion
        {
            get { return duration; }
            set { duration = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void Execute(AudioClip t)
        {
            base.Execute(t);
            if (crossFade != null)
            {
                crossFade(t, duration, volume);
                crossFade = null;
            }
        }
        #endregion

        #region 公开方法


        public override void Dispose()
        {
            base.Dispose();
            duration = 1;
            volume = 1;
        }

        /// <summary>
        /// 设置淡入淡出事件
        /// </summary>
        /// <param name="value"></param>
        public void SetCrossFade(Action<AudioClip, float, float> value)
        {
            crossFade = value;
        }
        #endregion
    }
}