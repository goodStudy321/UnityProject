/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/16 23:13:00
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 延迟激活animation 主要为了修复换装不播动画问题
    /// </summary>
    public class UnitAnimDelayEnable
    {
        #region 字段

        #endregion

        #region 属性
        private Animation anim;

        public Animation Anim
        {
            get { return anim; }
            set { anim = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private IEnumerator SetEnable()
        {
            if (anim == null)
            {
                ObjPool.Instance.Add(this);
                yield break;
            }
            anim.enabled = false;
            for (int i = 0; i < 2; i++)
            {
                yield return new WaitForEndOfFrame();
            }
            if (anim == null)
            {
                ObjPool.Instance.Add(this);
                yield break;
            }
            anim.enabled = true;
            ObjPool.Instance.Add(this);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Start(Animation anim)
        {
            Anim = anim;
            if (anim == null) return;
            Global.Main.StartCoroutine(SetEnable());
        }


        #endregion
    }
}