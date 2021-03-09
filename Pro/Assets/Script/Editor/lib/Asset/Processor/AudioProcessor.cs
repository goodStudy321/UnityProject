using System;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     *音频资源；WAV和AIFF格式适合较短音效,无压缩音质好不需解码
     *OGG和MP3适合背景音乐,有压缩轻微损失需解码
     *当发布到ANDROID或者IOS平台,强制将音频资源编码为MP3格式,所以移动平台的音频格式为MP3即可
    */

    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:音效处理器
    /// </summary>
    public static class AudioProcessor
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 音效文件导入之前
        /// </summary>
        /// <param name="assetImporter">音效导入者</param>
        /// <param name="assetPath">导入的音效文件路径</param>
        /// <param name="data">音效处理数据</param>
        public static void OnPre(AssetImporter assetImporter, string assetPath, AudioProcessorData data)
        {
            return;
        }

        /// <summary>
        /// 音效文件导入之后
        /// </summary>
        /// <param name="assetImporter">资源导入者</param>
        /// <param name="assetPath">导入的音效文件路径</param>
        /// <param name="audio">导入的音效文件</param>
        /// <param name="data">音效处理数据</param>
        public static void OnPost(AssetImporter assetImporter, string assetPath, AudioClip audio, AudioProcessorData data)
        {
            AudioImporter audioImporter = assetImporter as AudioImporter;
            AudioImporterSampleSettings setting = new AudioImporterSampleSettings();
            if (audio.length > 4) setting.loadType = AudioClipLoadType.Streaming;
            else setting.loadType = AudioClipLoadType.DecompressOnLoad;
            setting.sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate;
            setting.compressionFormat = AudioCompressionFormat.MP3;
            audioImporter.SetOverrideSampleSettings("Android", setting);
            audioImporter.SetOverrideSampleSettings("iPhone", setting);

            setting.compressionFormat = AudioCompressionFormat.Vorbis;
            audioImporter.defaultSampleSettings = setting;
        }
    }
    #endregion
}