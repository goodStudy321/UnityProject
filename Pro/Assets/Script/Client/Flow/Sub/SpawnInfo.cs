using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.05.20,10:24:36
    /// CO:nuolan1.ActionSoso1
    /// BG:出生相关信息
    /// </summary>
    [System.Serializable]
    public class SpawnInfo : VectorInfo
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        [SerializeField]
        private int rotY = 0;

        [SerializeField]
        private int typeID = 0;

        [SerializeField]
        private float duration = 0;

        [SerializeField]
        private string bornAnimID = "N9100";

        [SerializeField]
        private long uid = GuidTool.GenDateLong();

        #endregion

        #region 属性
        /// <summary>
        /// 角度
        /// </summary>
        public int RotY
        {
            get { return rotY; }
            set { rotY = value; }
        }

        /// <summary>
        /// 类型ID
        /// </summary>
        public int TypeID
        {
            get { return typeID; }
            set { typeID = value; }
        }

        /// <summary>
        /// 唯一ID
        /// </summary>
        public long UID
        {
            get { return uid; }
            set { uid = value; }
        }

        /// <summary>
        /// 出生间隔
        /// </summary>
        public float Duration
        {
            get { return duration; }
            set { duration = value; }
        }

        /// <summary>
        /// 出生动画
        /// </summary>
        public string BornAnimID
        {
            get { return bornAnimID; }
            set { bornAnimID = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Copy(SpawnInfo other)
        {
            pos = other.pos;
            rotY = other.rotY;
            typeID = other.typeID;
            duration = other.duration;
            bornAnimID = other.bornAnimID;
            uid = GuidTool.GenDateLong();

        }

        public void Read(BinaryReader br)
        {
            ExVector.Read(ref pos, br);
            rotY = br.ReadInt32();
            typeID = br.ReadInt32();
            duration = br.ReadSingle();
            ExString.Read(ref bornAnimID, br);
            //bornAnimID = br.ReadString();
            uid = br.ReadInt64();
        }

        public void Write(BinaryWriter bw)
        {
            pos.Write(bw);
            bw.Write(rotY);
            bw.Write(typeID);
            bw.Write(duration);
            ExString.Write(bornAnimID, bw);
            //bw.Write(bornAnimID);
            bw.Write(uid);
        }


#if UNITY_EDITOR

        public void Draw(Object obj, IList lst, int idx)
        {
            EditorGUILayout.LongField("唯一ID(UID):", UID);
            UIEditLayout.UIntField("TypeID:", ref typeID, obj);
            UIEditLayout.Vector3Field("位置:", ref pos, obj);
            UIEditLayout.IntSlider("角度:", ref rotY, 0, 360, obj);
            UIEditLayout.FloatField("出生间隔:", ref duration, obj);
            UIEditLayout.TextField("出生动画:", ref bornAnimID, obj);

        }

        public override void OnSceneGUI(Object obj)
        {
            Vector3 rot = new Vector3(0, RotY, 0);
            Handles.ArrowHandleCap(obj.GetInstanceID(), pos, Quaternion.Euler(rot), 4f, EventType.Repaint);
        }
#endif

        #endregion
    }
}