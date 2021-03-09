using System;
using UnityEngine;
using System.Collections.Generic;
using AS = UnityEngine.AudioSource;

namespace Loong.Game
{


    /// <summary>
    /// AU:Loong
    /// TM:2014.4.10
    /// BG:音效类
    /// </summary>
    public class Audio : Sound
    {
        #region 字段
        private Transform root = null;
        /// <summary>
        /// 正在使用的音源列表
        /// </summary>
        private List<AS> used = new List<AS>();

        /// <summary>
        /// 没有使用的音源列表
        /// </summary>
        private List<AS> unused = new List<AS>();

        //// LY add begin ////

        private AS replaceAS = null;
        private Timer mWaitTimer = null;
        private bool theOnePlaying = false;

        //// LY add end ////

        public static readonly Audio Instance = new Audio();
        #endregion

        #region 属性

        #endregion
        private Audio()
        {
            Init();
        }


        #region 私有方法
        /// <summary>
        /// 获取可用音源
        /// </summary>
        /// <returns></returns>
        private AS GetSource()
        {
            AS source = null;
            int last = unused.Count - 1;
            if (last < 0)
            {
                source = AudioTool.CreateSource(root, "None");
                AudioTool.Set2DSource(source);
                used.Add(source);
            }
            else
            {
                source = unused[last];
                unused.RemoveAt(last);
            }
            return source;
        }

        //// LY add begin ////
        
        private void TheOneClipFin()
        {
            StopTheOneClip();
        }

        //// LY add end ////

        #endregion

        #region 保护方法  

        protected override void SetVolume()
        {
            int length = used.Count;
            for (int i = 0; i < length; i++)
            {
                used[i].volume = Volume;
            }
        }

        protected override void CrossFade(AudioClip clip, float duration, float volume)
        {
            AS source = GetSource();
            source.volume = volume;
            source.name = clip.name;
            source.clip = clip;
            source.Play();
            AudioClipTimer.Create(source);

            float newLen = CheckCrossFade(clip, duration);
            iTween.AudioFrom(source.gameObject, 0, source.volume, newLen);
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            if (root != null) return;
            root = TransTool.CreateRoot<Audio>();
            for (int i = 0; i < 18; i++)
            {
                AS source = AudioTool.CreateSource(root, "None");
                AudioTool.Set2DSource(source);
                unused.Add(source);
            }

            //// LY add begin ////
            
            replaceAS = AudioTool.CreateSource(root, "TheOneAS");
            AudioTool.Set2DSource(replaceAS);

            mWaitTimer = ObjPool.Instance.Get<Timer>();
            //// LY add end ////
        }

        public override void PlayClip(AudioClip clip, float voume = 1)
        {
            AS source = GetSource();
            source.name = clip.name;
            source.volume = voume;
            source.clip = clip;
            source.Play();
            AudioClipTimer.Create(source);
        }

        /// <summary>
        /// 停止
        /// </summary>
        public override void Stop()
        {
            int length = used.Count;
            for (int i = 0; i < length; i++) used[i].Stop();
        }

        /// <summary>
        /// 暂停
        /// </summary>
        public override void Pause()
        {
            int length = used.Count;
            for (int i = 0; i < length; i++) used[i].Pause();
        }

        /// <summary>
        /// 重新播放
        /// </summary>
        public override void Resume()
        {
            int length = used.Count;
            for (int i = 0; i < length; i++) used[i].UnPause();
        }

        /// <summary>
        /// 向没有使用的音源列表添加项
        /// </summary>
        /// <param name="source"></param>
        public void AddUnUsed(AS source)
        {
            if(used.Contains(source))
            {
                used.Remove(source);
            }
            unused.Add(source);
        }

        //// LY add begin ////

        public override void PlayTheOneClip(AudioClip clip, float voume = 1)
        {
            if (replaceAS == null)
                return;

            StopTheOneClip();

            replaceAS.name = clip.name;
            replaceAS.volume = voume;
            replaceAS.clip = clip;
            replaceAS.Play();

            mWaitTimer.Seconds = clip.length;
            mWaitTimer.complete += TheOneClipFin;
            mWaitTimer.Start();

            theOnePlaying = true;
        }

        public void StopTheOneClip()
        {
            if(theOnePlaying == false)
            {
                return;
            }

            mWaitTimer.complete -= TheOneClipFin;
            mWaitTimer.Stop();

            replaceAS.Stop();
            replaceAS.name = "TheOneAS";
            replaceAS.clip = null;

            theOnePlaying = false;
        }

        //// LY add end ////

        #endregion
    }
}