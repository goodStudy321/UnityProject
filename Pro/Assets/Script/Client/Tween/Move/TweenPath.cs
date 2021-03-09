using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.15
    /// BG:路径移动动画
    /// </summary>
    [Serializable]
    public class TweenPath : TweenBase
    {
        #region 字段

        /// <summary>
        /// 点索引
        /// </summary>
        private int index = -1;

        /// <summary>
        /// true:等待中
        /// </summary>
        private bool delay = false;

        /// <summary>
        /// 计时
        /// </summary>
        private float count = 0;

        /// <summary>
        /// 两点之间的百分比
        /// </summary>
        private float percent = 0;

        /// <summary>
        /// true:逆行
        /// </summary>
        private bool reverce = false;

        [SerializeField]
        private bool relative = false;

        [SerializeField]
        private bool orientPath = false;

        private Transform target = null;

        /// <summary>
        /// 当前目标点
        /// </summary>
        private PointInfo current = null;

        /// <summary>
        /// 起始位置
        /// </summary>
        private Vector3 begPos = Vector3.zero;

        [SerializeField]
        private List<PointInfo> points = new List<PointInfo>();
        #endregion

        #region 属性

        /// <summary>
        /// true:相对位置,启动时将路径平移到起点和游戏对象位置相同
        /// </summary>
        public bool Relative
        {
            get { return relative; }
            set { relative = value; }
        }

        /// <summary>
        /// true:沿着点方向
        /// </summary>
        public bool OrientPath
        {
            get { return orientPath; }
            set { orientPath = value; }
        }

        /// <summary>
        /// 目标物体
        /// </summary>
        public Transform Target
        {
            get { return target; }
            set { target = value; }
        }

        /// <summary>
        /// 点列表
        /// </summary>
        public List<PointInfo> Points
        {
            get { return points; }
            set { points = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public TweenPath()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 设置平移
        /// </summary>
        private void SetRelative()
        {
            Vector3 dif = target.position - Points[0].pos;
            int length = Points.Count;
            for (int i = 0; i < length; i++)
            {
                PointInfo point = Points[i];
                point.pos += dif;
            }
        }

        /// <summary>
        /// 移动到下一点
        /// </summary>
        private void MoveNext()
        {
            count = 0;
            delay = false;
            percent = 0;
            int max = Points.Count - 1;
            #region 到达终点
            if (Mode == LoopMode.Once)
            {
                index++;
                if (index > max)
                {
                    Complete();
                    Stop();
                    return;
                }
            }
            else if (Mode == LoopMode.Loop)
            {
                index++;
                if (index > max)
                {
                    Complete();
                    index = 0;
                }
            }
            else if (Mode == LoopMode.PingPong)
            {
                if (reverce)
                {
                    index--;
                    if (index < 1)
                    {
                        index = 1;
                        reverce = false;
                        Complete();
                    }
                }
                else
                {
                    index++;
                    if (index > max)
                    {
                        index = max;
                        reverce = true;
                        Complete();
                    }
                }
            }

            #endregion

            #region 设置开始位置和当前点
            if (reverce)
            {
                int cur = index - 1;
                begPos = points[index].pos;
                current = points[cur];
            }
            else
            {
                if (index == 0)
                {
                    begPos = Target.position;
                }
                else
                {
                    int last = index - 1;
                    begPos = Points[last].pos;
                }
                current = Points[index];
            }

            if (current.Duration == 0)
            {
                Target.position = current.pos;
                if (current.Delay == 0)
                {
                    MoveNext();
                }
                else
                {
                    delay = true;
                }
            }

            #endregion
            #region 设置方向
            if (OrientPath)
            {
                Vector3 direction = current.pos - begPos;
                direction.Normalize();
                Target.rotation = Quaternion.LookRotation(direction);
            }
            #endregion
        }


        #endregion

        #region 保护方法

        protected override void StartCustom()
        {
            if (Target == null)
            {
                iTrace.Error("Loong", "路径移动没有设置目标");
                Dispose(); return;
            }
            if (Points == null || Points.Count == 0)
            {
                iTrace.Error("Loong", "路径移动没有设置路径点");
                Dispose(); return;
            }
            if (Relative) SetRelative();
            MoveNext();
        }

        protected override void ResetCustom()
        {
            count = 0;
            index = -1;
            delay = false;
            percent = 0;
        }

        protected override void DisposeCustom()
        {
            Target = null;
            current = null;
            reverce = false;
            Relative = false;
            OrientPath = false;
            while (Points.Count != 0)
            {
                int last = points.Count - 1;
                var pi = points[last];
                Points.RemoveAt(last);
                ObjPool.Instance.Add(pi);
            }
        }


        protected override void UpdateCustom()
        {
            count += IgnoreTimeScale ? Time.unscaledDeltaTime : Time.deltaTime;
            if (delay)
            {
                if (count >= current.Delay)
                {
                    MoveNext();
                }
            }
            else
            {
                if (current.Duration == 0)
                {
                    target.position = current.pos;
                    MoveNext(); return;
                }
                percent = count / current.Duration;
                if (percent < 1)
                {
                    target.position = begPos * (1 - percent) + current.pos * percent;
                }
                else
                {
                    target.position = current.pos;
                    if (current.Delay == 0)
                    {
                        MoveNext();
                    }
                    else
                    {
                        delay = true;
                        count = 0;
                    }
                }
            }
        }
        #endregion

        #region 公开方法
        public void Read(string path)
        {
            using (var fs = new FileStream(path, FileMode.Open))
            {
                Read(fs);
            }
        }

        public void Read(byte[] arr)
        {
            using (var stream = new MemoryStream(arr))
            {
                Read(stream);
            }
        }

        public void Read(Stream stream)
        {
            using (var reader = new BinaryReader(stream, Encoding.UTF8))
            {
                IgnoreTimeScale = reader.ReadBoolean();
                relative = reader.ReadBoolean();
                orientPath = reader.ReadBoolean();
                int length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    var point = ObjPool.Instance.Get<PointInfo>();
                    point.Read(reader);
                    points.Add(point);
                }
            }
        }

        public void Copy(TweenPath other)
        {

            while (Points.Count > 0)
            {
                var last = Points.Count - 1;
                var point = Points[last];
                ObjPool.Instance.Add(point);
                Points.RemoveAt(last);
            }

            IgnoreTimeScale = other.IgnoreTimeScale;
            relative = other.relative;
            orientPath = other.orientPath;
            int length = other.points.Count;
            for (int i = 0; i < length; i++)
            {
                var point = other.points[i];
                var newP = ObjPool.Instance.Get<PointInfo>();
                newP.Copy(point);
                points.Add(newP);
            }
        }

        public void Save(string path)
        {
            using (var fs = new FileStream(path, FileMode.OpenOrCreate))
            {
                using (var write = new BinaryWriter(fs, Encoding.UTF8))
                {
                    write.Write(IgnoreTimeScale);
                    write.Write(relative);
                    write.Write(orientPath);
                    int length = points.Count;
                    write.Write(length);
                    for (int i = 0; i < length; i++)
                    {
                        var point = points[i];
                        point.Write(write);
                    }
                }
            }
        }
        #endregion

#if UNITY_EDITOR
        private int select = 0;

        public void OnSceneGUI(Object obj)
        {
            UIHandleTool.Begin();
            UIDrawTool.Buttons(obj, "路径点列表", "路径点", points.Count, ref select);
            UIHandleTool.End();
            UIVectorUtil.DrawInfos<PointInfo>(obj, points, Color.magenta, "路径点", select, true);
        }

        public override void Draw(Object obj)
        {
            base.Draw(obj);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("朝向路径:", ref orientPath, obj);
            UIEditLayout.Toggle("相对位置:", ref relative, obj);
            if (relative) UIEditLayout.HelpInfo("启动时将路径平移到起点和游戏对象位置相同");
            EditorGUILayout.EndVertical();
            UIDrawTool.IDrawLst<PointInfo>(obj, points, "Points", "路径点");
        }
#endif
    }
}