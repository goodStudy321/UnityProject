using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.10
    /// BG:背景音乐类
    /// </summary>
    public class Music : Sound
    {
        #region 字段

        private AudioSource source = null;

        public static readonly Music Instance = new Music();
        #endregion

        #region 属性
        /// <summary>
        /// 音源
        /// </summary>
        public AudioSource Source
        {
            get { return source; }
            set { source = value; }
        }

        #endregion

        #region 构造方法
        private Music()
        {
            Init();
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void SetVolume()
        {
            source.volume = Volume;
        }

        protected override void CrossFade(AudioClip clip, float dur, float volume)
        {
            source.name = clip.name;
            source.clip = clip;
            source.Play();
            float newLen = CheckCrossFade(clip, dur);
            iTween.AudioFrom(source.gameObject, 0, source.volume, newLen);
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            Transform root = TransTool.CreateRoot<Music>();
            GameObject go = new GameObject("music");
            source = go.AddComponent<AudioSource>();
            go.transform.parent = root;
            AudioTool.Set2DSource(source);
            source.loop = true;
        }

        public override void PlayClip(AudioClip clip, float volume = 1)
        {
            source.volume = GetVolume(volume);
            source.name = clip.name;
            source.clip = clip;
            source.Play();
        }


        /// <summary>
        /// 停止
        /// </summary>
        public override void Stop()
        {
            source.Stop();
        }

        /// <summary>
        /// 暂停
        /// </summary>
        public override void Pause()
        {
            source.Pause();
        }

        /// <summary>
        /// 重新播放
        /// </summary>
        public override void Resume()
        {
            source.UnPause();
        }
        #endregion
    }
}