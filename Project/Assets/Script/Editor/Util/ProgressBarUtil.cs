using System;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using UnityEditor.Callbacks;
using System.Collections.Generic;
using Random = UnityEngine.Random;
using Object = UnityEngine.Object;


namespace Hello.Edit
{
    public class ProgressBarUtil
    {
        private static int max = 10;

        private static int count = 0;

        private static int isShowVal = -1;

        private const string isShowName = "isShow";

        public const int Pri = MenuTool.NormalPri + 10;

        public const string menu = EditUtil.menu + "进度条/";

        public const string AMenu = MenuTool.AHello + "进度条/";

        public const string IsShowPath = menu + "运行显示";

        public static int Max
        {
            get { return max; }
            set { max = value; }
        }

        public static bool IsShow
        {
            get
            {
                if (Application.isBatchMode)
                {
                    return false;
                }
                if (isShowVal == -1)
                {
                    isShowVal = GetIsShowVal();
                }
                return (isShowVal != 0);
            }
            set
            {
                int val = (value ? 1 : 0);
                EditPrefsTool.SetInt(typeof(ProgressBarUtil), isShowName, val);
            }
        }

        [DidReloadScripts]
        private static void Reset()
        {
            isShowVal = GetIsShowVal();
        }

        private static int GetIsShowVal()
        {
            return EditPrefsTool.GetInt(typeof(ProgressBarUtil), isShowName, 1);
        }

        private static bool GetIsShow()
        {
            var val = EditPrefsTool.GetInt(typeof(ProgressBarUtil), isShowName, 1);
            if (val == 0) return false;
            return true;
        }

        [MenuItem(IsShowPath,true,Pri+2)]
        private static bool GetMenuIsShow()
        {
            var val = GetIsShow();
            Menu.SetChecked(IsShowPath, val);
            return true;
        }

        [MenuItem(IsShowPath, false, Pri + 2)]
        private static void SetMenuIsShow()
        {
            int val = GetIsShowVal();
            val = (val == 0 ? 1 : 0);
            isShowVal = val;
            EditPrefsTool.SetInt(typeof(ProgressBarUtil), isShowName, val);
        }

        [MenuItem(menu + "清理 #&C", false, Pri)]
        [MenuItem(AMenu + "清理", false, Pri)]
        private static void ClearPrograss()
        {
            EditorUtility.ClearProgressBar();
        }

        [MenuItem(menu + "清理缓存", false, Pri + 1)]
        [MenuItem(AMenu + "清理缓存", false, Pri + 1)]
        private static void ClearCache()
        {
            EditPrefsTool.Delete(typeof(ProgressBarUtil), isShowName);
            UIEditTip.Log("清理缓存成功");
        }

        public static void Show(string title, string msg, float pro)
        {
            if (!IsShow) return;
            if (string.IsNullOrEmpty(msg)) msg = "";
            if (string.IsNullOrEmpty(title)) title = "请稍候";
            if (count < 1)
            {
                EditorUtility.DisplayProgressBar(title, msg, pro);
            }
            ++count;
            if (count > max) count = 0;
        }

        public static void Show(string title, string msg)
        {
            if (!IsShow) return;
            float pro = Random.Range(0f, 1f);
            Show(title, msg, pro);
        }

        public static void Clear()
        {
            count = 0;
            if (!IsShow) return;
            EditorUtility.ClearProgressBar();
        }

        public static void Refresh()
        {
            count = 0;
        }
    }
}

