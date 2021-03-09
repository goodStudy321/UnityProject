/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/7/5 00:00:00
 ============================================================================*/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using AudioDic = Dictionary<string, AudioClip>;

    /// <summary>
    /// 音效片段对象池
    /// </summary>
    public class AudioPool
    {
        #region 字段

        /// <summary>
        /// 音效片段字典
        /// </summary>
        private static AudioDic dic = new AudioDic();

        public static readonly AudioPool Instance = new AudioPool();
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        private AudioPool()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 添加音效
        /// </summary>
        /// <param name="name">音效名称(含后缀)</param>
        /// <param name="clip"></param>
        public void Add(string name, AudioClip clip)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (clip == null) return;
            if (dic.ContainsKey(name))
            {
                var val = dic[name];
                if (val == null) dic[name] = val;
            }
            else
            {
                dic.Add(name, clip);
            }
        }

        public AudioClip Get(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            if (dic.ContainsKey(name)) return dic[name];
            return null;
        }

        public void Dispose()
        {
            dic.Clear();
        }
        #endregion
    }
}