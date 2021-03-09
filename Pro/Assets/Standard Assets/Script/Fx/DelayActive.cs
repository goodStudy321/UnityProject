using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        d26ed80f-ebbb-4d31-aa97-233ac625df0e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/30 20:39:15
    /// BG:
    /// </summary>
    public class DelayActive : MonoBehaviour
    {
        #region 字段
        private Coroutine hiddenCorou = null;

        public float begHiddenTime = 1f;

        public bool active = false;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Start()
        {
            gameObject.SetActive(!active);
        }

        private void OnEnable()
        {
            hiddenCorou = StartCoroutine(Hidden());
        }
        private IEnumerator Hidden()
        {
            yield return new WaitForSeconds(begHiddenTime);
            gameObject.SetActive(active);
            hiddenCorou = null;
        }

        private void OnDestroy()
        {
            if (hiddenCorou != null)
            {
                StopCoroutine(hiddenCorou);
            }
            hiddenCorou = null;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}