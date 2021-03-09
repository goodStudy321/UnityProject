using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.08.08
    /// BG:点信息
    /// </summary>
    [System.Serializable]
    public class PointInfo : VectorInfo
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        [SerializeField]
        private float delay = 0f;

        [SerializeField]
        private float duration = 1f;

        #endregion

        #region 属性

        /// <summary>
        /// 到达此点停顿时间
        /// </summary>
        public float Delay
        {
            get { return delay; }
            set { delay = value; }
        }

        /// <summary>
        /// 到底此点需要时间
        /// </summary>
        public float Duration
        {
            get { return duration; }
            set { duration = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Read(BinaryReader reader)
        {
            delay = reader.ReadSingle();
            duration = reader.ReadSingle();
            ExVector.Read(ref pos, reader);
        }

        public void Copy(PointInfo other)
        {
            delay = other.delay;
            duration = other.duration;
            pos = other.pos;
        }

        public void Write(BinaryWriter write)
        {
            write.Write(delay);
            write.Write(duration);
            pos.Write(write);
        }
        #endregion

#if UNITY_EDITOR
        public void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.Vector3Field("位置", ref pos, obj);
            UIEditLayout.Slider("到达此点需要时间(秒)", ref duration, 0, 200, obj);
            UIEditLayout.Slider("到达此点停顿时间(秒)", ref delay, 0, 200, obj);
        }
#endif
    }
}