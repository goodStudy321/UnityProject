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
     * TODO:和CamPathNode可重构
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/12 17:33:24
    /// BG:路径移动基类
    /// </summary>
    [Serializable]
    public class PathNodeBase : FlowChartNode
    {
        #region 字段

        private int index = 0;

        private float count;

        private ObjPathInfo info;

        private bool isDelay;

        private Vector3 from;

        private Vector3 to;

        /// <summary>
        /// 移动目标
        /// </summary>
        protected Transform target = null;

        /// <summary>
        /// 路径移动点
        /// </summary>
        public List<ObjPathInfo> path = new List<ObjPathInfo>();
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
        #endregion

        #region 保护方法
        /// <summary>
        /// 最后一个点等待
        /// </summary>
        /// <returns></returns>
        protected IEnumerator YieldComplete(float duration)
        {
            yield return new WaitForSeconds(duration);
            Complete();
        }

        /// <summary>
        /// 设置高度
        /// </summary>
        protected virtual void SetPathInfo()
        {
            int length = path.Count;
            for (int i = 0; i < length; i++)
            {
                var info = path[i];
                info.SetPos();
            }
        }


        protected void SetInfo(int index, Vector3 beg)
        {
            info = path[index];
            from = beg;
            to = info.pos;
            if (info.orient)
            {
                var orie = (to - from).normalized;
                target.forward = orie;
            }
        }

        protected override void ReadyCustom()
        {
            Clear();
            SetInfo(0, target.position);
        }

        protected override void ProcessUpdate()
        {
            count += Time.deltaTime;
            if (index < path.Count)
            {
                if (isDelay)
                {
                    if (count > info.delay)
                    {
                        isDelay = false;
                        count = 0;
                        index += 1;
                        if (index < path.Count)
                        {
                            SetInfo(index, to);
                        }
                    }
                }
                else
                {
                    float t = count / info.duration;

                    if (count > info.duration)
                    {
                        target.position = to;
                        count = 0;
                        if (info.delay > 0)
                        {
                            isDelay = true;
                        }
                        else
                        {
                            index += 1;
                            if (index < path.Count)
                            {
                                SetInfo(index, to);
                            }
                        }
                    }
                    else
                    {
                        Vector3 pos = from + (to - from) * t;
                        target.position = pos;
                    }
                }
            }
            else
            {
                Complete();
            }
        }
        #endregion

        #region 公开方法

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            int length = br.ReadInt32();
            for (int i = 0; i < length; i++)
            {
                var it = new ObjPathInfo();
                it.Read(br);
                path.Add(it);
            }
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            int length = path.Count;
            bw.Write(length);
            for (int i = 0; i < length; i++)
            {
                var it = path[i];
                it.Write(bw);
            }
        }

        public override void Initialize()
        {
            base.Initialize();
            SetPathInfo();
        }

        public override void Dispose()
        {
            base.Dispose();
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

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as PathNodeBase;
            if (node == null) return;
            int length = node.path.Count;
            for (int i = 0; i < length; i++)
            {
                var oi = node.path[i];
                var info = new ObjPathInfo();
                info.Copy(oi);
                path.Add(info);
            }
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }

        protected override void EditDrawCtrlUI(Object o)
        {
            UIDrawTool.Buttons(o, "移动路径点按钮列表", "路径点", path.Count, ref placeIndex);
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("groupbox");
            EditorGUILayout.Space();
            EditorGUILayout.HelpBox("通过在场景视图中, Ctrl+左键点击,可以添加路径点并设置位置", MessageType.Info);
            EditorGUILayout.HelpBox("通过在场景视图中,选择对应点按钮,Ctrl+右键键点击,可以设置路径点位置", MessageType.Info);
            UIDrawTool.IDrawLst<ObjPathInfo>(o, path, "ObjPathInfos", "移动路径点:");
            EditorGUILayout.EndVertical();
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            UIVectorUtil.AddInfo<ObjPathInfo>(o, path, "移动路径点", e.control);
            UIVectorUtil.SetInfo<ObjPathInfo>(o, path, placeIndex, "移动路径点", e.control);
            UIVectorUtil.DrawInfos<ObjPathInfo>(o, path, Color.yellow, "移动路径点", placeIndex, true);
        }
#endif
        #endregion
    }
}