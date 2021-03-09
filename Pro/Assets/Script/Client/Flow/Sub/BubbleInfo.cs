using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        f62f061d-a1f1-4bb3-9b08-3a005e66f1fd
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/10/26 11:32:27
    /// BG:气泡信息
    /// </summary>
    [Serializable]
    public class BubbleInfo : BubbleBaseInfo
    {
        #region 字段
        [SerializeField]
        private long uid = 0;

        #endregion

        #region 属性

        /// <summary>
        /// 唯一ID
        /// </summary>
        public long UID
        {
            get { return uid; }
            set { uid = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public BubbleInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
        }

        public override void Copy(BubbleBaseInfo other)
        {
            base.Copy(other);

            var info = other as BubbleInfo;
            uid = info.uid;
        }
        #endregion

#if UNITY_EDITOR
        public override void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.UlongField("UID:", ref uid, obj);
            if (uid < 1) UIEditLayout.HelpInfo("本地英雄");
            base.Draw(obj, lst, idx);
        }
#endif
    }
}