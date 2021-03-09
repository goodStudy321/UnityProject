using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Object = UnityEngine.Object;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:
    /// BG:延迟时间
    /// </summary>
    [Serializable]
    public class DelayNode : FlowChartNode
    {
        #region 字段

        private float cnt = 0;

        private float pro = 0;

        private float icnt = 0;

        private GameObject ui = null;

        /// <summary>
        /// 信息组件
        /// </summary>
        private UILabel msgLbl = null;

        /// <summary>
        /// 进度组件
        /// </summary>
        private UISprite proSp = null;


        /// <summary>
        /// 延迟时间
        /// </summary>
        public float delayTime = 0.5f;

        /// <summary>
        /// 是否使用进度条
        /// </summary>
        public bool usePro = false;

        /// <summary>
        /// 进度条标题 DELETE
        /// </summary>
        public string title = "标题";


        public int titleID = 0;

        /// <summary>
        /// 进度条显示方式,0代表增加,1代表减少
        /// </summary>
        public int showType = 0;


        /// <summary>
        /// 进度条资源名称
        /// </summary>
        public string proName = "UIDelay";

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void LoadCb(GameObject go)
        {
            ui = go;
            Transform root = go.transform;
            go.transform.parent = UIMgr.Root;
            go.transform.localPosition = Vector3.zero;
            go.transform.localScale = Vector3.one;
            string des = this.GetType().Name;
            proSp = ComTool.Get<UISprite>(root, "sliderFg", des);
            UILabel title = ComTool.Get<UILabel>(root, "title", des);
            if (title != null) title.text = Localization.Instance.GetDes(titleID);

            msgLbl = ComTool.Get<UILabel>(root, "msg", des);

            Format();

        }
        /// <summary>
        /// 重置计时器
        /// </summary>
        private void Clear()
        {
            if (ui == null) return;
            iTool.Destroy(ui);
            ui = null;
        }

        private void Format()
        {
            long ticks = (long)((delayTime - cnt) * 10000000);
            TimeSpan span = TimeSpan.FromTicks(ticks);
            msgLbl.text = DateTool.Format(span);
        }
        #endregion

        #region 保护方法


        protected override void ReadyCustom()
        {
            cnt = 0;
            pro = 0;
            icnt = 0;
            if (usePro) AssetMgr.LoadPrefab(proName, LoadCb);
        }

        protected override void ProcessUpdate()
        {
            icnt += Time.unscaledDeltaTime;
            cnt += Time.unscaledDeltaTime;
            pro = cnt / delayTime;
            if (usePro)
            {
                if (proSp != null)
                {
                    proSp.fillAmount = ((showType > 0) ? (1 - pro) : pro);
                }
            }
            if (icnt > 1)
            {
                icnt = 0;
                if (msgLbl != null) Format();
            }


            if (cnt > delayTime)
            {
                Complete();
            }
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
            delayTime = br.ReadSingle();
            usePro = br.ReadBoolean();
            ExString.Read(ref title, br);
            titleID = br.ReadInt32();
            showType = br.ReadInt32();
            ExString.Read(ref proName, br);
            //proName = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(delayTime);
            bw.Write(usePro);
            ExString.Write(title, bw);
            bw.Write(titleID);
            bw.Write(showType);
            ExString.Write(proName, bw);
            //bw.Write(proName);
        }

        /// <summary>
        /// 启动进度条
        /// </summary>
        public void StartProgress()
        {
            StartProcess();
        }

        /// <summary>
        /// 停止进度条
        /// </summary>
        public void StopProgress()
        {
            Complete();
        }



        public override void Preload()
        {
            PreloadMgr.prefab.Add(proName);
        }

        public override void Reset()
        {
            base.Reset();
            Clear();
        }

        public override void Dispose()
        {
            Clear();
        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }
        #endregion



        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }


        private string[] showTypeArr = new string[] { "增加", "减少" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as DelayNode;
            if (node == null) return;
            delayTime = node.delayTime;
            usePro = node.usePro;
            titleID = node.titleID;
            showType = node.showType;
            proName = node.proName;
        }

        private void DrawProgressInfo(Object obj)
        {
            proName = EditorGUILayout.TextField("进度条名称:", proName);
            title = EditorGUILayout.TextField("标题:", title);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("标题ID:", ref titleID, obj);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();
            //msg = EditorGUILayout.TextField("信息:", msg);
            showType = EditorGUILayout.Popup("显示方式:", showType, showTypeArr);

        }

        protected override void EditDrawDebug(Object o)
        {
            if (Transition != TransitionState.Update) return;
            EditorGUILayout.Slider(pro, 0, 1);
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical("groupbox");
            delayTime = EditorGUILayout.FloatField("延迟时间/秒:", delayTime);
            EditorGUILayout.BeginVertical("groupbox");
            usePro = EditorGUILayout.Toggle("使用进度条:", usePro);
            if (usePro) DrawProgressInfo(o);
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}