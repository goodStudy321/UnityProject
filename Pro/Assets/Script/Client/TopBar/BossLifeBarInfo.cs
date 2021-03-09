using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.6.13
    /// BG:Boss血条信息
    /// </summary>
    public class BossLifeBarInfo : IDisposable
    {
        #region 字段

        private UISlider bg = null;

        private UISlider fg = null;

        #endregion

        #region 属性
        /// <summary>
        /// 缓冲伤害
        /// </summary>
        public UISlider Bg
        {
            get { return bg; }
            set { bg = value; }
        }

        /// <summary>
        /// 直接伤害
        /// </summary>
        public UISlider Fg
        {
            get { return fg; }
            set { fg = value; }
        }
        #endregion

        #region 构造方法
        public BossLifeBarInfo()
        {

        }
        public BossLifeBarInfo(UISlider bg, UISlider fg)
        {
            this.bg = bg;
            this.fg = fg;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 更新
        /// </summary>
        public void Update()
        {
            bg.value = Mathf.Lerp(bg.value, fg.value, Time.deltaTime * 2);
        }

        /// <summary>
        /// 设置进度
        /// </summary>
        public void SetValue(float value)
        {
            fg.value = value;
        }

        /// <summary>
        /// 打开
        /// </summary>
        public void Open()
        {
            bg.gameObject.SetActive(true);
        }

        /// <summary>
        /// 关闭
        /// </summary>
        public void Close()
        {
            bg.gameObject.SetActive(false);
        }

        /// <summary>
        /// 向前打开
        /// </summary>
        public void OpenForward()
        {
            bg.gameObject.SetActive(true);
            bg.foregroundWidget.depth = 3;
            fg.foregroundWidget.depth = 4;
        }

        /// <summary>
        /// 重置
        /// </summary>
        public void Reset()
        {
            bg.value = 1f;
            bg.foregroundWidget.depth = 1;
            fg.value = 1f;
            fg.foregroundWidget.depth = 2;
        }

        /// <summary>
        /// 释放
        /// </summary>
        public void Dispose()
        {
            Reset();
            Bg = null;
            Fg = null;
        }
        #endregion
    }
}