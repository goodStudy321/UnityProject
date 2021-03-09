using System;
using System.IO;
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
     * GUID:        cebb2d8f-e320-4d07-bb1a-3c0f31476213
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/15 16:38:24
    /// BG:
    /// </summary>
    [Serializable]
    public abstract class BubbleNodeBase<T> : FlowChartNode where T : BubbleBaseInfo, new()
    {
        #region 字段

        protected float ht = 0;

        /// <summary>
        /// 记时
        /// </summary>
        protected float cnt = 0;

        /// <summary>
        /// 当前索引
        /// </summary>
        protected int idx = 0;


        /// <summary>
        /// 气泡变换组件
        /// </summary>
        protected Transform bTran = null;

        /// <summary>
        /// 气泡显示的目标变换组件
        /// </summary>
        protected Transform target = null;

        /// <summary>
        /// 当前气泡信息
        /// </summary>
        protected T cur = null;

        /// <summary>
        /// 气泡信息列表
        /// </summary>
        [SerializeField]
        protected List<T> infos = new List<T>();


        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public BubbleNodeBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void Next()
        {
            ++idx;
            cnt = 0;
            SetBubble();
        }

        protected virtual void SetBubble()
        {
        }


        protected virtual void StartUp(GameObject go)
        {
            if (go == null)
            {
                Complete();
            }
            else
            {
                bTran = go.transform;
                bTran.parent = UIMgr.Root;
                bTran.localScale = Vector3.one;
            }
        }

        protected override void ReadyCustom()
        {
            cnt = 0;
            idx = 0;
            if (infos.Count < 1)
            {
                Complete();
            }
            else
            {
                AssetMgr.LoadPrefab("UIBubble", StartUp);
            }
        }

        protected override void ProcessUpdate()
        {
            if (bTran == null) return;
            if (target == null) return;
            cnt += Time.unscaledDeltaTime;
            if (cnt < cur.dur)
            {
                Vector3 wPos = target.position;
                wPos.y += ht;
                Vector3 sPos = CameraMgr.Main.WorldToScreenPoint(wPos);
                sPos.z = 0;
                Vector3 rPos = UIMgr.Cam.ScreenToWorldPoint(sPos);
                rPos.x += cur.x;
                bTran.position = rPos;
            }
            else
            {
                int len = infos.Count - 1;
                if (idx >= len)
                {
                    Complete();
                }
                else
                {
                    Next();
                }
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            target = null;
            Clear();
        }

        protected virtual void Clear()
        {
            if (bTran != null) GbjPool.Instance.Add(bTran.gameObject);
            bTran = null;
        }
        #endregion

        #region 公开方法
        public override void Preload()
        {
            PreloadMgr.prefab.Add("UIBubble");
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

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var t = new T();
                t.Read(br);
                infos.Add(t);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            int length = infos.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var t = infos[i];
                t.Write(bw);
            }
        }

        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as BubbleNodeBase<T>;
            if (node == null) return;
            int length = node.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var oi = node.infos[i];
                var info = new T();
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
            UIDrawTool.IDrawLst<T>(o, infos, "Infos", "信息列表");
        }
#endif
        #endregion
    }
}