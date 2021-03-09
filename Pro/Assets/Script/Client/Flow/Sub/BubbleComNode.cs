using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        261cfe3c-53a1-4709-a5cb-4e301ed1c52a
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/15 17:14:50
    /// BG:
    /// </summary>
    [Serializable]
    public class BubbleComNode : BubbleNodeBase<BubbleComInfo>
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public BubbleComNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void StartUp(GameObject go)
        {
            base.StartUp(go);
            if (go == null) return;
            SetBubble();
        }
        protected override void SetBubble()
        {
            cur = infos[idx];
            string comName = cur.comName;
            var go = ComponentBind.Get(comName);
            target = (go == null) ? null : go.transform;
            if (target == null)
            {
                LogError(string.Format("未发现键值为:{0}的组件", comName));
                Complete();
            }
            else
            {
                UILabel textLbl = ComTool.Get<UILabel>(bTran, "text", "气泡");
                textLbl.text = Localization.Instance.GetDes(cur.textID);

                ht = cur.ht;
            }
        }

        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR
        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }
#endif
    }
}