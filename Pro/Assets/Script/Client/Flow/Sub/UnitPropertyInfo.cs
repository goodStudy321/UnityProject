using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        3ada13e2-543c-4d8a-89ee-deef553ac569
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/4 11:20:47
    /// BG:属性信息
    /// </summary>
    [Serializable]
    public class UnitPropertyInfo
#if UNITY_EDITOR
        : IDraw
#endif
    {
        #region 字段
        [SerializeField]
        private long uid = 0;

        /// <summary>
        /// 百分比
        /// </summary>
        public int percent = 0;

        /// <summary>
        /// 比较类型
        /// </summary>
        public CompareType compareType = CompareType.Leq;

        /// <summary>
        /// 逻辑类型
        /// </summary>
        public ListenerPropertyType propertyType = ListenerPropertyType.Hp;
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

        #region 构造方法
        public UnitPropertyInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Read(BinaryReader br)
        {
            uid = br.ReadInt64();
            percent = br.ReadInt32();
            compareType = (CompareType)br.ReadInt32();
            propertyType = (ListenerPropertyType)br.ReadInt32();

        }

        public void Write(BinaryWriter bw)
        {
            bw.Write(uid);
            bw.Write(percent);
            bw.Write((int)compareType);
            bw.Write((int)propertyType);
        }

        public void DrawRuntime()
        {

        }

        #endregion

#if UNITY_EDITOR

        private string[] compareArr = new string[] { "小于等于", "大于等于" };

        private string[] propertyArr = new string[] { "血量" };

        public void Draw(Object obj, IList lst, int idx)
        {
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.LongField("单位UID:", ref uid, obj);
            if (uid == -1)
            {
                EditorGUILayout.LabelField("英雄");
            }
            else if (uid < -1)
            {
                UIEditLayout.HelpError("无效值");
            }
            EditorGUILayout.EndVertical();
            UIEditLayout.IntSlider("百分比:", ref percent, 0, 100, obj);
            compareType = (CompareType)EditorGUILayout.Popup("比较类型:", (int)compareType, compareArr);
            propertyType = (ListenerPropertyType)EditorGUILayout.Popup("属性类型:", (int)propertyType, propertyArr);
        }
#endif


    }

}