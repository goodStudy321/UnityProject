using System;
using System.IO;
using UnityEngine;
using Loong.Game;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        079f7bef-109c-4162-a50c-3ecc50a9cee2
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/7 10:47:02
    /// BG:
    /// </summary>
    [Serializable]
    public class DebugFlowNode : FlowChartNode
    {
        #region 字段
        public string msg = "";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Debug.Log(Format(msg));
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            //msg = br.ReadString();
            ExString.Read(ref msg, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            //bw.Write(msg);
            ExString.Write(msg, bw);
        }
        #endregion

#if UNITY_EDITOR
        public override void EditDrawProperty(Object o)
        {
            UIEditLayout.TextArea("测试信息", ref msg, o, null, GUILayout.Height(160));
        }
#endif
    }
}