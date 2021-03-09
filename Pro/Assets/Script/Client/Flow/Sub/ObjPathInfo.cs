using System;
using System.IO;
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
     * GUID:        eadbf4fe-7122-4101-a36f-24992fd5d63d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/12 16:18:27
    /// BG:对象路径信息
    /// </summary>
    [Serializable]
    public class ObjPathInfo : VectorInfo
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        public float duration = 1f;

        public float delay = 0f;

        public float height = 0f;

        public bool orient = false;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public ObjPathInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void SetPos()
        {
            pos.y += height;
        }

        public void Read(BinaryReader br)
        {
            ExVector.Read(ref pos, br);
            duration = br.ReadSingle();
            delay = br.ReadSingle();
            height = br.ReadSingle();
            orient = br.ReadBoolean();
        }

        public void Write(BinaryWriter bw)
        {
            pos.Write(bw);
            bw.Write(duration);
            bw.Write(delay);
            bw.Write(height);
            bw.Write(orient);
        }

        public void Copy(ObjPathInfo other)
        {
            pos = other.pos;
            duration = other.duration;
            delay = other.delay;
            height = other.height;
            orient = other.orient;
        }
        #endregion


#if UNITY_EDITOR
        public void Draw(Object obj, IList lst, int idx)
        {
            pos = EditorGUILayout.Vector3Field("位置", pos);
            duration = EditorGUILayout.FloatField("持续时间/秒:", duration);
            if (duration < 0) duration = 0;
            delay = EditorGUILayout.FloatField("停顿时间/秒:", delay);
            if (delay < 0) delay = 0;
            height = EditorGUILayout.FloatField("高度/米:", height);
            if (height < 0) height = 0;
            orient = EditorGUILayout.Toggle("朝向路径:", orient);
        }
#endif
    }
}