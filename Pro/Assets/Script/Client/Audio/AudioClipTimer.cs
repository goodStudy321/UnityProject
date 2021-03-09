using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        dc594159-12e9-496a-86fe-a0b5e22afccd
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/2/19 17:18:32
    /// BG:计算音效播放时间
    /// </summary>
    public class AudioClipTimer : Timer
    {
        #region 字段

        private AudioSource source = null;

        #endregion

        #region 属性
        public AudioSource Source
        {
            get { return source; }
            set { source = value; }
        }
        #endregion

        #region 构造方法
        public AudioClipTimer()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override void Start()
        {
            base.Start();
            if (source == null) return;
            if (source.clip == null) return;
            Seconds = source.clip.length;
        }


        public override void Stop()
        {
            base.Stop();
            Audio.Instance.AddUnUsed(Source);
            source.name = "None";
            source.clip = null;
            source = null;
        }

        /// <summary>
        /// 创建音效播放时间计时器
        /// </summary>
        /// <param name="source"></param>
        public static void Create(AudioSource source)
        {
            if (source == null) return;
            AudioClipTimer timer = ObjPool.Instance.Get<AudioClipTimer>();
            timer.AutoPool = true;
            timer.Source = source;
            timer.Start();
        }
        #endregion
    }
}