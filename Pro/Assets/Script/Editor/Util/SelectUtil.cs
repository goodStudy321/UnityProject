using System;
using Hello.Game;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;

namespace Hello.Edit
{
    public static class SelectUtil
    {
        public const int Pri = MenuTool.NormalPri + 25;

        public const string menu = MenuTool.Hello + "选择工具/";

        public const string AMenu = MenuTool.AHello + "选择工具/";

        private static int SortByLen(string lhs,string rhs)
        {
            if(lhs.Length < rhs.Length)
            {
                return -1;
            }
            if(lhs.Length > rhs.Length)
            {
                return 1;
            }
            return 0;
        }

        public static T[] Get<T>(SelectionMode mode = SelectionMode.DeepAssets) where T : Object
        {
            string msg = "请稍后...";
            float pro = UnityEngine.Random.Range(0.1f, 0.8f);
            ProgressBarUtil.Show("", msg, pro);
            var objs = Selection.GetFiltered<T>(mode);
            ProgressBarUtil.Clear();
            return objs;
        }

        public static bool CheckObjs()
        {
            var objs = Selection.objects;
            if(objs == null || (objs.Length == 0))
            {
                UIEditTip.Warning("没有选择任何对象");
                return false;
            }
            return true;
        }

        public static bool CheckGos()
        {
            var gos = Selection.gameObjects;
            if(gos == null || (gos.Length == 0))
            {
                UIEditTip.Warning("没有选择任何对象");
                return false;
            }
            return true;
        }

        public static T[] Get<T>(SelectionMode mode,string suffix) where T : Object
        {
            T[] selects = Selection.GetFiltered<T>(mode);
            if (selects == null) return null;
            if (string.IsNullOrEmpty(suffix)) return selects;
            List<T> lst = null;
            int length = selects.Length;
            for (int i = 0; i < length; i++)
            {
                T select = selects[i];
                string path = AssetDatabase.GetAssetPath(select);
                string sfx = Path.GetExtension(path);
                if (sfx != suffix) continue;
                if (lst == null) lst = new List<T>();
                lst.Add(select);
            }
            T[] arr = (lst == null) ? null : lst.ToArray();
            return arr;
        }

        public static List<string> GetPath<T>(SelectionMode mode,string suffix) where T : Object
        {
            T[] selects = Selection.GetFiltered<T>(mode);
            if (selects == null) return null;
            if (string.IsNullOrEmpty(suffix)) return null;
            List<string> lst = null;
            int length = selects.Length;
            for (int i = 0; i < length; i++)
            {
                T select = selects[i];
                string path = AssetDatabase.GetAssetPath(select);
                string sfx = Path.GetExtension(path);
                if (sfx != suffix) continue;
                if (lst == null) lst = new List<string>();
                lst.Add(path);
            }
            return lst;
        }

        public static string[] GetDepends<T>(SelectionMode mode = SelectionMode.DeepAssets) where T : Object
        {
            var objs = Get<T>();
            if (objs == null) return null;
            float length = objs.Length;
            List<string> lst = null;
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                var sfx = Path.GetExtension(path);
                if (string.IsNullOrEmpty(sfx)) continue;
                if (lst == null) lst = new List<string>();
                lst.Add(path);
            }
            if (lst == null) return null;
            var paths = AssetDatabase.GetDependencies(lst.ToArray());
            return paths;
        }

        public static string GetDir()
        {
            var objs = Selection.GetFiltered<Object>(SelectionMode.Assets);
            if (objs == null || objs.Length < 1) return null;
            int length = objs.Length;
            var cur = Directory.GetCurrentDirectory();
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                var fullPath = Path.Combine(cur, path);
                if (Directory.Exists(fullPath)) return fullPath;
            }
            return null;
        }

        public static List<string> GetDirs()
        {
            var objs = Selection.GetFiltered<Object>(SelectionMode.Assets);
            if (objs == null || objs.Length < 1) return null;
            int length = objs.Length;
            var rDirs = new List<string>();
            var cur = Directory.GetCurrentDirectory();
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                var fullPath = Path.Combine(cur, path);
                if (!Directory.Exists(fullPath)) continue;
                rDirs.Add(path);
            }
            if (rDirs.Count < 1) return null;
            rDirs.Sort(SortByLen);
            length = rDirs.Count;
            var dirs = new List<string>();
            dirs.Add(rDirs[0]);
            bool contains = false;
            for (int i = 0; i < length; i++)
            {
                var dir = rDirs[i];
                contains = false;
                for (int j = 0; j < dirs.Count; j++)
                {
                    var pDir = dirs[j];
                    if (dir.StartsWith(pDir))
                    {
                        contains = true;
                        break;
                    }
                }
                if (contains) continue;
                dirs.Add(dir);
            }

            length = dirs.Count;
            for (int i = 0; i < length; i++)
            {
                var path = dirs[i];
                var fullPath = Path.Combine(cur, path);
                dirs[i] = fullPath;
            }
            return dirs;
        }

        /// <summary>
        /// 显示选择对象标记
        /// </summary>
        [MenuItem(menu + "显示选择对象标记", false, Pri)]
        [MenuItem(AMenu + "显示选择对象标记", false, Pri)]
        public static void ShowFlags()
        {
            if (!CheckObjs()) return;
            Object[] objs = Selection.objects;
            int length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                Object obj = objs[i];
                iTrace.Log("Hello", string.Format("{0}的标记为:{1}", obj.name, obj.hideFlags));
            }
        }

        /// <summary>
        /// 删除选择对象
        /// </summary>
        [MenuItem(menu + "删除选择对象", false, Pri + 1)]
        [MenuItem(AMenu + "删除选择对象", false, Pri + 1)]
        public static void Delete()
        {
            if (!CheckObjs()) return;
            if (!EditorUtility.DisplayDialog("", "删除所选对象?", "确定", "取消")) return;
            Object[] objs = Selection.objects;
            int length = objs.Length;
            Scene scene = EditorSceneManager.GetActiveScene();
            for (int i = 0; i < length; i++)
            {
                Object obj = objs[i];
                string path = AssetDatabase.GetAssetPath(obj);
                if (!string.IsNullOrEmpty(path)) continue;
                EditorSceneManager.MarkSceneDirty(scene);
                iTool.Destroy(obj);
            }
        }

        [MenuItem(menu + "显示选择对象路径", false, Pri + 2)]
        [MenuItem(AMenu + "显示选择对象路径", false, Pri + 2)]
        public static void ShowPath()
        {
            if (!CheckObjs()) return;
            Object[] objs = Selection.objects;
            int length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                Object obj = objs[i];
                string path = AssetDatabase.GetAssetPath(obj);
                if (string.IsNullOrEmpty(path))
                {
                    path = "无,这可能是场景中的对象";
                }
                iTrace.Log("Hello", string.Format("{0}的路径:{1}", obj.name, path));
            }
        }

        [MenuItem(menu + "显示变换信息", false, Pri + 3)]
        [MenuItem(AMenu + "显示变换信息", false, Pri + 3)]
        public static void ShowTranInfo()
        {
            Transform tran = Selection.activeTransform;
            if (tran == null) return;
            iTrace.Log("Hello", "父节点:" + ((tran.parent == null) ? "空" : tran.parent.name));
            iTrace.Log("Hello", "根节点:" + ((tran.root == null) ? "空" : tran.root.name));
            iTrace.Log("Hello", "完整路径:" + TransTool.GetPath(tran));

        }


        [MenuItem(menu + "设置选择游戏对象激活隐藏 %q", false, Pri + 4)]
        [MenuItem(AMenu + "设置选择游戏对象激活", false, Pri + 4)]
        public static void SetActive()
        {
            var at = EditPrefsTool.GetBool(typeof(SelectUtil), "SetActive", false);
            at = !at;
            EditPrefsTool.SetBool(typeof(SelectUtil), "SetActive", at);
            var gos = Selection.gameObjects;
            if (gos == null || gos.Length < 1)
            {
                UIEditTip.Log("未选择任何游戏对象");
            }
            else
            {
                int length = gos.Length;
                for (int i = 0; i < length; i++)
                {
                    var go = gos[i];
                    EditUtil.RegisterUndo("SetSelectActive", go);
                    go.SetActive(at);
                }
                UIEditTip.Log("设置{0}完毕", at ? "激活" : "隐藏");
            }
        }

        /// <summary>
        /// 选择文件夹后获取对象列表
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="type"></param>
        /// <returns></returns>
        public static List<T> Get<T>(AssetType type) where T : Object
        {
            var dirs = GetDirs();
            List<T> objs = null;
            if (dirs == null || dirs.Count < 1)
            {
                var arr = Selection.objects;
                if (arr == null || arr.Length < 1)
                {
                    UIEditTip.Warning("未选择任何文件夹或者文件");
                }
                else
                {
                    objs = new List<T>();
                    int length = arr.Length;
                    for (int i = 0; i < length; i++)
                    {
                        var o = arr[i];
                        if (!(o is T)) continue;
                        T t = o as T;
                        objs.Add(t);
                    }
                }
            }
            else
            {
                var lst = AssetQueryUtil.Search(dirs, type);
                if (lst == null)
                {
                    UIEditTip.Warning("无匹配资源");
                    return null;
                }
                objs = new List<T>();
                var title = "校验资源中···";
                float len = lst.Count;
                for (int i = 0; i < len; i++)
                {
                    var path = lst[i];
                    ProgressBarUtil.Show(title, path, i / len);
                    var obj = AssetDatabase.LoadAssetAtPath<T>(path);
                    if (obj == null) continue;
                    objs.Add(obj);
                }
            }
            return objs;
        }

        public static List<string> GetPath(AssetType type)
        {
            var dirs = GetDirs();
            List<string> paths = null;
            if (dirs == null || dirs.Count < 1)
            {
                var arr = Selection.objects;
                if (arr == null || arr.Length < 1)
                {
                    return null;
                }
                else
                {
                    paths = new List<string>();
                    float length = arr.Length;
                    for (int i = 0; i < length; i++)
                    {
                        var o = arr[i];
                        var path = AssetDatabase.GetAssetPath(o);
                        if (string.IsNullOrEmpty(path)) continue;
                        ProgressBarUtil.Show("", o.name, i / length);
                        paths.Add(path);
                    }
                }
            }
            else
            {
                var lst = AssetQueryUtil.Search(dirs, type);
                paths = lst;
            }
            return paths;
        }

        /// <summary>
        /// 获取选择的游戏对象列表
        /// </summary>
        /// <returns></returns>
        public static List<GameObject> Prefab()
        {
            return Get<GameObject>(AssetType.Prefab);
        }

        /// <summary>
        /// 获取选择的所有对象列表
        /// </summary>
        /// <returns></returns>
        public static List<Object> All()
        {
            return Get<Object>(AssetType.All);
        }
    }
}

