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
    /*
     * TODO:和PathNodeBase可重构
     */

    /// <summary>
    /// AU:Loong
    /// TM:
    /// BG:用于控制相机移动路径,包括瞬间移动和路径移动
    /// </summary>
    public class CamPathNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 信息索引
        /// </summary>
        private int index = 0;

        private float count;

        private PointInfo info;

        private bool isDelay;

        private Vector3 from;

        private Vector3 to;

        /// <summary>
        /// 相机初始位置
        /// </summary>
        private Vector3 oriPos;

        /// <summary>
        /// 初始角度
        /// </summary>
        private Vector3 oriEuler;


        /// <summary>
        /// 是否需要按返回
        /// </summary>
        public bool needReturn;

        /// <summary>
        /// 等待多少时间之后返回
        /// </summary>
        public float delayReturnTime;

        /// <summary>
        /// 目标角度
        /// </summary>
        public Vector3 tarEuler = Vector3.zero;

        /// <summary>
        /// 移动路径
        /// </summary>
        public List<PointInfo> path = new List<PointInfo>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Clear()
        {
            index = 0;
            count = 0;
        }

        /// <summary>
        /// 设置路径点
        /// </summary>
        private void SetPathInfo()
        {
            float y = CameraMgr.transform.position.y;
            int length = path.Count;
            for (int i = 0; i < length; i++)
            {
                Vector3 pos = path[i].pos;
                pos.Set(pos.x, y, pos.z);
                path[i].pos = pos;
            }
        }

        private void AddInfo()
        {
            index += 1;
            if (index < path.Count)
            {
                info = path[index];
                from = to;
                to = info.pos;
            }
        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            //SetPathInfo();
            CameraMgr.Lock = true;
            /// LY add begin ///
            if (CameraMgr.CamOperation != null)
            {
                ((CameraPlayerNewOperation)CameraMgr.CamOperation).ResetCamToDefPosImd();
            }
            /// LY add end ///
            oriPos = CameraMgr.Main.transform.position;
            if (tarEuler != Vector3.zero)
            {
                oriEuler = CameraMgr.transform.eulerAngles;
                CameraMgr.transform.eulerAngles = tarEuler;
            }
            Clear();
            info = path[0];
            from = oriPos;
            to = info.pos;
            //isDelay = (info.Delay > 0);
        }

        protected override void ProcessUpdate()
        {
            count += Time.deltaTime;
            if (index < path.Count)
            {
                if (isDelay)
                {
                    if (count > info.Delay)
                    {
                        isDelay = false;
                        count = 0;
                        AddInfo();
                    }
                }
                else
                {
                    float t = count / info.Duration;

                    if (count > info.Duration)
                    {
                        CameraMgr.transform.position = to;
                        count = 0;
                        if (info.Delay > 0)
                        {
                            isDelay = true;
                        }
                        else
                        {
                            AddInfo();
                        }
                    }
                    else
                    {
                        Vector3 pos = from + (to - from) * t;
                        CameraMgr.transform.position = pos;
                    }
                }
            }
            else
            {
                if (delayReturnTime > 0)
                {
                    if (count > delayReturnTime)
                    {
                        Complete();
                    }
                }
                else
                {
                    Complete();
                }
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();

            if (needReturn) CameraMgr.Main.transform.position = oriPos;
            if (tarEuler != Vector3.zero)
            {
                CameraMgr.transform.eulerAngles = oriEuler;
            }
            CameraMgr.Lock = false;
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            needReturn = br.ReadBoolean();
            delayReturnTime = br.ReadSingle();
            ExVector.Read(ref tarEuler, br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new PointInfo();
                it.Read(br);
                path.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(needReturn);
            bw.Write(delayReturnTime);
            tarEuler.Write(bw);
            int length = path.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = path[i];
                it.Write(bw);
            }
        }
        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamPathNode;
            if (node == null) return;
            needReturn = node.needReturn;
            delayReturnTime = node.delayReturnTime;
            tarEuler = node.tarEuler;
            int length = node.path.Count;
            for (int i = 0; i < length; i++)
            {
                var oi = node.path[i];
                var info = new PointInfo();
                info.Copy(oi);
                path.Add(info);
            }
        }

        protected override void EditCompleteDynamicCustom()
        {
            Clear();
            iTween.Stop(CameraMgr.Main.gameObject);
            if (path.Count == 0) return;
            Vector3 pos = needReturn ? oriPos : path[path.Count - 1].pos;
            CameraMgr.Main.transform.position = pos;
        }

        protected override void EditDrawCtrlUI(Object o)
        {
            UIDrawTool.Buttons(o, "相机路径点按钮列表", "路径点", path.Count, ref placeIndex);
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            UIVectorUtil.AddInfo<PointInfo>(o, path, "相机路径点", e.control);
            UIVectorUtil.SetInfo<PointInfo>(o, path, placeIndex, "相机路径点", e.control);
            UIVectorUtil.DrawInfos<PointInfo>(o, path, Color.yellow, "路径点", placeIndex, true);
        }


        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical("box");
            UIEditLayout.Vector3Field("目标角度:", ref tarEuler, o);

            UIEditLayout.Toggle("是否返回原点", ref needReturn, o);

            if (needReturn)
            {
                EditorGUILayout.BeginHorizontal();
                EditorGUILayout.LabelField("等待多少时间后返回/单位秒:", GUILayout.Width(140));
                delayReturnTime = EditorGUILayout.FloatField(delayReturnTime);
                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.HelpBox("通过在场景视图中, Ctrl+左键点击,可以添加路径点并设置位置", MessageType.Info);
            EditorGUILayout.HelpBox("通过在场景视图中,选择对应点按钮,Ctrl+右键键点击,可以设置路径点位置", MessageType.Info);

            UIDrawTool.IDrawLst<PointInfo>(o, path, "CamPathInfo", "相机路径点");

        }
#endif
        #endregion
    }
}