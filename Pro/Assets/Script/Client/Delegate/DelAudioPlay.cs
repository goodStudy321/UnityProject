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
    /// 音效播放委托处理
    /// </summary>
    public class DelAudioPlay : DelAudioParam
    {
        #region 字段
        private float volume = 1;
        private Action<AudioClip, float> play = null;

        #endregion

        #region 属性
        public float Volume
        {
            get { return volume; }
            set { volume = value; }
        }
        #endregion

        #region 构造方法
        public DelAudioPlay()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void Execute(AudioClip t)
        {
            base.Execute(t);
            if (play != null)
            {
                play(t, volume);
                play = null;
            }
        }
        #endregion

        #region 公开方法
        public override void Dispose()
        {
            base.Dispose();
            volume = 1;
        }

        /// <summary>
        /// 设置播放事件
        /// </summary>
        /// <param name="value"></param>
        public void SetPlay(Action<AudioClip, float> value)
        {
            play = value;
        }
        #endregion
    }
}