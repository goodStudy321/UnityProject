using UnityEngine;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.10
    /// BG:声音基类
    /// </summary>
    public abstract class Sound
    {
        #region 字段
        private bool on = true;

        private float volume = 1;
        #endregion

        #region 属性
        /// <summary>
        /// true:开 false:关
        /// </summary>
        public bool On
        {
            get { return on; }
            set
            {
                on = value;
                if (!on) Stop();
            }
        }

        /// <summary>
        /// 音量 ∈[0,1]
        /// </summary>
        public float Volume
        {
            get { return volume; }
            set
            {
                volume = Mathf.Clamp01(value);
                SetVolume();
            }
        }

        #endregion

        #region 构造方法
        public Sound()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        /// <summary>
        /// 获取音量
        /// </summary>
        /// <param name="volume"></param>
        /// <returns></returns>
        protected float GetVolume(float volume)
        {
            volume = Mathf.Clamp(volume, 0, Volume);
            return volume;
        }

        /// <summary>
        /// 检查播放的条件
        /// </summary>
        protected virtual bool Check()
        {

            if (!on) return false;
            return true;
        }

        /// <summary>
        /// 检查淡入淡出的长度
        /// </summary>
        /// <param name="clip">音频文件</param>
        /// <param name="dur">持续时间</param>
        /// <returns></returns>
        protected float CheckCrossFade(AudioClip clip, float dur)
        {
            float clipLen = clip.length;
            float newLen = dur > clipLen ? clipLen : dur;
            return newLen;
        }

        /// <summary>
        /// 设置音量
        /// </summary>
        protected abstract void SetVolume();

        /// <summary>
        /// 自定义淡入淡出
        /// </summary>
        protected virtual void CrossFade(AudioClip clip, float dur, float volume = 1)
        {

        }

        #endregion

        #region 公开方法
        /// <summary>
        /// 播放
        /// </summary>
        public virtual void PlayClip(AudioClip clip, float volume = 1)
        {

        }

        public virtual void PlayTheOneClip(AudioClip clip, float voume = 1)
        {

        }

        /// <summary>
        /// 通过配置播放
        /// </summary>
        /// <param name="id"></param>
        /// <param name="volume"></param>
        public void PlayByID(int id, float volume = 1)
        {
            ushort realID = (ushort)id;
            var cfg = AudioCfgManager.instance.Find(realID);
            if (cfg == null)
            {
                iTrace.Error("Loong", "无ID为:{0}的音效配置", id);
            }
            else
            {
                Play(cfg.name, volume);
            }
        }

        /// 播放
        /// </summary>
        /// <param name="name">名称 包含后缀</param>
        /// <param name="volume">音量</param>
        public void Play(string name, float volume = 1)
        {
            if (!Check()) return;
            if (string.IsNullOrEmpty(name)) return;
            volume = GetVolume(volume);
            var clip = AudioPool.Instance.Get(name);
            if (clip != null)
            {
                PlayClip(clip, volume);
            }
            else
            {
                var dg = ObjPool.Instance.Get<DelAudioPlay>();
                dg.Name = name;
                dg.Volume = volume;
                dg.SetPlay(PlayClip);
                AssetMgr.Instance.Load(name, dg.Callback);
            }
        }

        //// LY add begin ////

        public void PlayTheOne(string name, float volume = 1)
        {
            if (!Check()) return;
            if (string.IsNullOrEmpty(name)) return;
            volume = GetVolume(volume);
            var clip = AudioPool.Instance.Get(name);
            if (clip != null)
            {
                PlayTheOneClip(clip, volume);
            }
            else
            {
                var dg = ObjPool.Instance.Get<DelAudioPlay>();
                dg.Name = name;
                dg.Volume = volume;
                dg.SetPlay(PlayTheOneClip);
                AssetMgr.Instance.Load(name, dg.Callback);
            }
        }

        //// LY add end ////

        /// <summary>
        /// 淡入淡出
        /// </summary>
        /// <param name="name">名称 包含后缀</param>
        /// <param name="dur">持续时间</param>
        /// <param name="volume">音量</param>
        public void CrossFade(string name, float dur = 1, float volume = 1)
        {
            if (!Check()) return;
            if (string.IsNullOrEmpty(name)) return;
            volume = GetVolume(volume);
            var clip = AudioPool.Instance.Get(name);
            if (clip != null)
            {
                CrossFade(clip, dur, volume);
            }
            else
            {
                var dg = ObjPool.Instance.Get<DelAudioCrossfade>();
                dg.Name = name;
                dg.Volume = volume;
                dg.Duragion = dur;
                dg.SetCrossFade(CrossFade);
                AssetMgr.Instance.Load(name, dg.Callback);
            }
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public abstract void Init();

        /// <summary>
        /// 停止
        /// </summary>
        public abstract void Stop();

        /// <summary>
        /// 暂停
        /// </summary>
        public abstract void Pause();
        /// <summary>
        /// 重新播放
        /// </summary>
        public abstract void Resume();

        #endregion
    }
}