using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Loong.Game;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        ba346b60-36b0-4aef-8d2f-84956a07a329
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/12 15:16:20
    /// BG:字幕节点
    /// </summary>
    [Serializable]
    public class UISubTitleNode : FlowChartNode
    {
        #region 字段
        private Coroutine coro = null;

        private Transform root = null;
        /// <summary>
        /// 信息标签
        /// </summary>
        private UILabel msgLbl = null;

        /// <summary>
        /// 信息列表
        /// </summary>
        public List<TextInfo> infos = new List<TextInfo>();

        public const string UIName = "UISubTitle";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Clear()
        {
            UIMgr.STCam.gameObject.SetActive(false);

            if (root != null)
            {
                Object.DestroyImmediate(root.gameObject, true);
            }
            if (coro != null)
            {
                MonoEvent.Stop(coro);
                coro = null;
            }
        }

        private void LoadCb(GameObject go)
        {
            root = go.transform;
            TransTool.AddChild(UIMgr.STCam.transform, root);
            msgLbl = ComTool.Get<UILabel>(root, "msg", name);
            coro = MonoEvent.Start(Yield());

            UIMgr.STCam.gameObject.SetActive(true);
        }

        private IEnumerator Yield()
        {
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                TextInfo info = infos[i];
                msgLbl.text = Localization.Instance.GetDes(info.textID);//info.text;
                yield return new WaitForSeconds(info.dur);

            }

            Complete();
        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            base.ReadyCustom();
            AssetMgr.LoadPrefab(UIName, LoadCb);

        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            Clear();
        }

        #endregion

        #region 公开方法

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new TextInfo();
                it.Read(br);
                infos.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            int length = infos.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = infos[i];
                it.Write(bw);
            }
        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }

        public override void Dispose()
        {
            Clear();
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(UIName);
        }
        #endregion

#if UNITY_EDITOR

        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UISubTitleNode;
            if (node == null) return;
            int length = node.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var oi = node.infos[i];
                var info = new TextInfo();
                info.Copy(oi);
                infos.Add(info);
            }
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            UIDrawTool.IDrawLst<TextInfo>(o, infos, "infos", "字幕列表");
        }
#endif
    }
}