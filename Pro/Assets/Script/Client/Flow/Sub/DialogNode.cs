using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using LuaInterface;
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
    /// BG:对话框节点
    /// </summary>
    [Serializable]
    public class DialogNode : FlowChartNode
    {

        #region 字段

        public List<DialogInfo> infos = new List<DialogInfo>();

        /// <summary>
        /// 是否关闭UI
        /// </summary>
        public bool closeUI = true;


        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        /// <summary>
        /// 打开回调
        /// </summary>
        /// <param name="uiName"></param>
        private void OpenCallback(string uiName)
        {
            EventMgr.Add(EventKey.UIClose, CloseCallback);
            EventMgr.Trigger("UpdateDataUIDialogList", infos, closeUI);
        }

        /// <summary>
        /// 关闭回调
        /// </summary>
        /// <param name="args"></param>
        private void CloseCallback(params object[] args)
        {
            string uiName = args[0] as string;
            if (uiName != UIName.UIDialog) return;
            EventMgr.Remove(EventKey.UIClose, CloseCallback);
            Complete();
        }


        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            UIMgr.Open(UIName.UIDialog, OpenCallback);
        }

        #endregion

        #region 公开方法

        public override void Initialize()
        {
            base.Initialize();
            if (infos.Count != 0) return;
            DialogInfo msg0 = new DialogInfo();
            msg0.modelName = "Actor_qiangxieshi";
            msg0.text = "鹅，鹅，鹅";
            infos.Add(msg0);

            DialogInfo msg1 = new DialogInfo();
            msg1.modelName = "Actor_qiangxieshi";
            msg1.text = "曲项向天歌";
            infos.Add(msg1);

            DialogInfo msg2 = new DialogInfo();
            msg2.modelName = "Actor_qiangxieshi";
            msg2.text = "白毛浮绿水";
            infos.Add(msg2);

            DialogInfo msg3 = new DialogInfo();
            msg3.modelName = "Actor_qiangxieshi";
            msg3.text = "红掌拨清波";
            infos.Add(msg3);

        }


        public override void Preload()
        {
            PreloadMgr.prefab.Add(UIName.UIDialog);
        }


        public override void Read(BinaryReader br)
        {
            base.Read(br);
            closeUI = br.ReadBoolean();
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new DialogInfo();
                it.Read(br);
                infos.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(closeUI);
            int length = infos.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = infos[i];
                it.Write(bw);
            }
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

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as DialogNode;
            if (node == null) return;
            closeUI = node.closeUI;
            int length = node.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var oi = node.infos[i];
                var info = new DialogInfo();
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
            EditorGUILayout.BeginVertical("groupbox");
            UIEditLayout.Toggle("是否关闭UI:", ref closeUI, o);
            UIDrawTool.IDrawLst<DialogInfo>(o, infos, "dialogInfos", "信息文本列表");
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}