using System;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    public class AssetDetailInfo : SelectAssetInfo, IComparable<AssetDetailInfo>, IComparer<AssetDetailInfo>
    {
        private long memUsage = 0;
        private long diskUsage = 0;
        private bool isAB = false;
        private string sfx = null;
        private string path = null;

        private string memUsageStr = null;
        private string diskUsageStr = null;

        private GUILayoutOption[] opts = new GUILayoutOption[] { GUILayout.Width(100) };

        private GUILayoutOption[] textOpts = new GUILayoutOption[] { GUILayout.Width(200) };

        public string Sfx
        {
            get { return sfx; }
            set { sfx = value; }
        }

        public bool IsAB
        {
            get { return isAB; }
            set { isAB = value; }
        }

        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        public long MemUsage
        {
            get { return memUsage; }
            set
            {
                memUsage = value;
                memUsageStr = EditorUtility.FormatBytes(memUsage);
            }
        }

        public long DiskUsage
        {
            get { return diskUsage; }
            set
            {
                diskUsage = value;
                diskUsageStr = ByteUtil.GetSizeStr(diskUsage);
            }
        }

        private void SetAB()
        {
            ABNameUtil.Set(path);
            IsAB = true;
            UIEditTip.Log("已设置");
        }

        private void SetNoneAB()
        {
            var path = AssetDatabase.GetAssetPath(Asset);
            ABTool.Remove(path);
            IsAB = false;
            UIEditTip.Log("已取消");
        }

        private void Delete()
        {
            var path = AssetDatabase.GetAssetPath(Asset);
            AssetDatabase.DeleteAsset(path);
            UIEditTip.Log("已删除");
        }


        public override void OnGUI(Object obj)
        {
            if(Asset == null)
            {
                EditorGUILayout.LabelField("已删除");
            }
            else
            {
                EditorGUILayout.TextField(Asset.name, textOpts);
                EditorGUILayout.LabelField(sfx, opts);
                EditorGUILayout.LabelField(diskUsageStr, opts);
                EditorGUILayout.LabelField(memUsageStr, opts);
                GUILayout.FlexibleSpace();
                if (GUILayout.Button("定位", opts))
                {
                    EditUtil.Ping(Asset);
                }
                if (IsAB)
                {
                    if (GUILayout.Button("取消AB", opts))
                    {
                        DialogUtil.Show("", "取消AB", SetNoneAB);
                    }
                    GUILayout.Box("", StyleTool.Label3, UIOptUtil.plus);
                }
                else
                {
                    if (GUILayout.Button("设置AB", opts))
                    {
                        DialogUtil.Show("", "设置AB", SetAB);
                    }
                    GUILayout.Box("", StyleTool.Label6, UIOptUtil.plus);
                }
                if (GUILayout.Button("删除", opts))
                {
                    Delete();
                }
            }
        }

        public virtual int CompareTo(AssetDetailInfo rhs)
        {
            if (rhs == null) return 0;
            if (memUsage < rhs.memUsage) return 1;
            if (memUsage > rhs.memUsage) return -1;
            return 0;
        }

        public virtual int Compare(AssetDetailInfo lhs, AssetDetailInfo rhs)
        {
            if (lhs == null) return 0;
            return lhs.CompareTo(rhs);
        }

        public static int CompareDisk(AssetDetailInfo lhs, AssetDetailInfo rhs)
        {
            if (rhs == null || lhs == null) return 0;
            if (lhs.diskUsage < rhs.diskUsage) return 1;
            if (lhs.diskUsage > rhs.diskUsage) return -1;
            return 0;
        }

        public static int CompareName(AssetDetailInfo lhs, AssetDetailInfo rhs)
        {
            if (rhs == null || lhs == null) return 0;
            return lhs.Asset.name.CompareTo(rhs.Asset.name);
        }
    }
}

