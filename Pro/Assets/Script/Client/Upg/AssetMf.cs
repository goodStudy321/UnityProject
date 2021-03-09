/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/2 16:49:20
 ============================================================================*/

using System;
using System.IO;
using System.Xml;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using Md5Dic = Dictionary<string, Md5Info>;
    using StopWatch = System.Diagnostics.Stopwatch;
    /// <summary>
    /// 资源清单
    /// </summary>
    public static class AssetMf
    {
        #region 字段

        private static long writeDur = 18000L;

        private static StopWatch watch = new StopWatch();

        private static List<int> lvs = new List<int>();

        /// <summary>
        /// 清单文件路径
        /// </summary>
        private static string mfPath = "";

        /// <summary>
        /// 备份清单路径
        /// </summary>
        private static string tmpMfPath = "";

        private static Md5Dic dic = null;

        /// <summary>
        /// k:资源名,对于AB去除后缀名,v:MD5Info
        /// </summary>
        private static Md5Dic nameDic = new Md5Dic();

        private static bool isStop = false;

        /// <summary>
        /// 清单内容
        /// </summary>
        private static Md5Set md5Set = new Md5Set();

        /// <summary>
        /// 清单文件名
        /// </summary>
        public const string Name = "Manifest.xml";

        /// <summary>
        /// 备份清单路径
        /// </summary>
        public const string TmpName = "TmpManifest.xml";

        /// <summary>
        /// 首包清单文件名
        /// </summary>
        public const string BaseName = "ManifestBase.xml";

        #endregion

        #region 属性
        /// <summary>
        /// 最小等级段
        /// </summary>
        public static int MinLv
        {
            get { return (lvs == null ? 0 : lvs[0]); }
        }

        /// <summary>
        /// 最大等级段
        /// </summary>
        public static int MaxLv
        {
            get { return (lvs == null ? int.MaxValue : lvs[lvs.Count - 1]); }
        }

        /// <summary>
        /// 内容字典,k:相对路径,v:MD5Info
        /// </summary>
        public static Md5Dic Dic
        {
            get { return dic; }
        }

        /// <summary>
        /// 内容列表
        /// </summary>
        public static List<Md5Info> Infos
        {
            get { return md5Set.infos; }
        }

        public static bool IsStop
        {
            get { return isStop; }
            set { isStop = value; }
        }

        /// <summary>
        /// 写入间隔,单位毫秒
        /// </summary>
        public static long WriteDur
        {
            get { return writeDur; }
            set { writeDur = value; }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 加载清单文件
        /// </summary>
        private static void Load()
        {
            mfPath = GetPath(Name);
            tmpMfPath = GetPath(TmpName);
            bool damaged = false;
            if (md5Set.Read(mfPath))
            {
                dic = Read(md5Set);
                FileTool.SafeCopy(mfPath, tmpMfPath);
                //var count = (dic == null ? -1 : dic.Count);
                //Debug.LogFormat("Loong, read mf suc,count:{0}", count);
            }
            else
            {
                damaged = true;
                Debug.Log("Loong,read mf count=0");
            }

            if (damaged)
            {
                md5Set.Read(tmpMfPath);
                dic = Read(md5Set);
                FileTool.SafeCopy(tmpMfPath, mfPath);
                var count = (dic == null ? -1 : dic.Count);
                Debug.LogFormat("Loong,read mf from temp,count:{0}", count);
            }
#if LOONG_SUB_ASSET
            SetName(md5Set);
#endif
        }

        private static void SetName(Md5Set set)
        {
            if (set == null) return;
            var infos = set.infos;
            if (infos == null || infos.Count == 0) return;
            var length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                AddName(info);
            }
        }

        private static void AddName(Md5Info info)
        {
            if (info == null) return;
            var path = info.path;
            string name = Path.GetFileName(path);
            if (nameDic.ContainsKey(name)) return;
            nameDic.Add(name, info);

        }

        /// <summary>
        /// 获取文件的完整路径
        /// </summary>
        /// <param name="name">名称</param>
        /// <returns></returns>
        private static string GetPath(string name)
        {
            return string.Format("{0}/{1}", AssetPath.Persistent, name);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public static void Init()
        {
            lvs.Add(39);
            lvs.Add(86);

#if UNITY_EDITOR && LOONG_TEST_UPG
            Load();
#else
            Load();
#endif
        }

        /// <summary>
        /// 通过配置设置等级段
        /// </summary>
        public static void SetLvs()
        {
#if LOONG_SUB_ASSET
            byte id = 34;
            var cfg = GlobalDataManager.instance.Find(id);
            if (cfg == null)
            {
                var err = string.Format("GlobalData ID:{0} not exist", id);
                iTrace.Error("Loong", err);
            }
            else
            {
                lvs.Clear();
                var nums = cfg.num2.list;
                var length = nums.Count;
                for (int i = 0; i < length; i++)
                {
                    var lv = (int)nums[i];
                    lvs.Add(lv);
                }
                lvs.Sort();
            }
#endif
        }

        /// <summary>
        /// 直接保存
        /// </summary>
        public static void Save()
        {
            if (md5Set == null) return;
            if (mfPath == null) return;
            if (tmpMfPath == null) return;
            md5Set.Save(mfPath);
            FileTool.SafeCopy(mfPath, tmpMfPath);
        }


        /// <summary>
        /// 保存键值信息
        /// </summary>
        /// <param name="path"></param>
        /// <param name="info"></param>
        public static void Save(string path, Md5Info info, bool force = false)
        {
            info.Op = 3;
            var infos = md5Set.infos;
            if (dic.ContainsKey(path))
            {
                var last = dic[path];
                last.Copy(info);
            }
            else
            {
                dic.Add(path, info);
                infos.Add(info);
                infos.Sort();
#if LOONG_SUB_ASSET
                AddName(info);
#endif
            }
            if (force)
            {
                Save();
                StartWatch();
            }
            else
            {
                if (watch.ElapsedMilliseconds > writeDur)
                {
                    Save();
                    StartWatch();
                }
            }

        }

        /// <summary>
        /// 删除指定列表的资源
        /// </summary>
        /// <param name="deletes">删除列表</param>
        public static void Delete(List<Md5Info> deletes)
        {
            if (deletes == null || deletes.Count < 1) return;
            int length = deletes.Count;
            for (int i = 0; i < length; i++)
            {
                var info = deletes[i];
                var path = info.path;
                if (!dic.ContainsKey(path)) continue;
                dic.Remove(path);
                var fullPath = GetPath(path);
                FileTool.SafeDelete(fullPath);
            }
            var infos = md5Set.infos;
            infos.Clear();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                infos.Add(it.Value);
            }
            infos.Sort();
            Save();
        }

        /// <summary>
        /// 读取MD5信息并将其转换为字典
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <returns></returns>
        public static Md5Dic Read(string path)
        {
            var set = ReadSet(path);
            return Read(set);
        }

        /// <summary>
        /// 读取压缩文件清单字典
        /// </summary>
        /// <param name="src">源文件路径</param>
        /// <param name="dest">解压后文件路径</param>
        /// <returns></returns>
        public static Md5Dic ReadComped(string src, string dest)
        {
            var set = ReadSetComped(src, dest);
            return Read(set);
        }

        /// <summary>
        /// 读取压缩文件清单字典,以文件名称作为K
        /// </summary>
        /// <param name="src"></param>
        /// <param name="dest"></param>
        /// <returns></returns>
        public static Md5Dic ReadCompedByName(string src, string dest)
        {
            var set = ReadSetComped(src, dest);
            return ReadByName(set);
        }

        public static Md5Set ReadSet(string path)
        {
            var set = new Md5Set();
            set.Read(path);
            return set;
        }

        public static Md5Set ReadSetComped(string src, string dest)
        {
            var decomp = DecompFty.Create();
            decomp.Src = src;
            decomp.Dest = dest;
            if (decomp.Execute())
            {
                return ReadSet(dest);
            }
            else
            {
                return null;
            }
        }

        /// <summary>
        /// 异步读取清单字典
        /// </summary>
        /// <param name="src">清单压缩文件路径</param>
        /// <param name="dest">清单解压文件路径</param>
        /// <param name="cb"></param>
        public static void ReadCompedAsync(string src, string dest, Action<Md5Dic> cb)
        {
            ReadSetCompedAsync(src, dest, (set) =>
              {
                  var dic = Read(set);
                  if (cb != null) cb(dic);
              });
        }

        /// <summary>
        /// 异步读取清单集合
        /// </summary>
        /// <param name="src">清单压缩文件路径</param>
        /// <param name="dest">清单解压文件路径</param>
        /// <param name="cb"></param>
        public static void ReadSetCompedAsync(string src, string dest, Action<Md5Set> cb)
        {
            WwwTool.LoadAsync(src, (bytes) =>
             {
                 Md5Set set = null;
                 if (bytes != null)
                 {
                     var name = Path.GetFileName(dest);
                     var cachePath = AssetPath.Cache + name;
                     using (var fs = new FileStream(cachePath, FileMode.Create))
                     {
                         fs.Write(bytes, 0, bytes.Length);
                     }
                     set = ReadSetComped(cachePath, dest);
                 }
                 if (cb != null) cb(set);
             });
        }


        /// <summary>
        /// 读取MD5信息并将其转换为字典
        /// </summary>
        /// <param name="set">md5信息</param>
        /// <returns></returns>
        public static Md5Dic Read(Md5Set set)
        {
            if (set == null || set.infos == null || set.infos.Count == 0) return null;
            var dic = new Md5Dic();
            int length = set.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = set.infos[i];
                if (dic.ContainsKey(info.path)) continue;
                dic.Add(info.path, info);
            }
            return dic;
        }

        /// <summary>
        /// 读取MD5信息并以名称为字典
        /// </summary>
        /// <param name="set"></param>
        /// <returns></returns>
        public static Md5Dic ReadByName(Md5Set set)
        {
            if (set == null || set.infos == null || set.infos.Count == 0) return null;
            var dic = new Md5Dic();
            int length = set.infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = set.infos[i];
                var name = Path.GetFileName(info.path);
                if (dic.ContainsKey(name)) continue;
                dic.Add(name, info);
            }
            return dic;
        }

        /// <summary>
        /// 将MD5信息字典写入文件
        /// </summary>
        /// <param name="dic">字典</param>
        /// <param name="path">文件路径</param>
        public static void Write(Md5Dic dic, string path)
        {
            if (dic == null || dic.Count == 0) return;
            var infos = new List<Md5Info>();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                infos.Add(it.Value);
            }
            Write(infos, path);
        }

        /// <summary>
        /// 将MD5集合写入文件
        /// </summary>
        /// <param name="set"></param>
        /// <param name="path"></param>
        public static void Write(Md5Set set, string path)
        {
            set.Save(path);
        }

        /// <summary>
        /// 将MD5信息列表写入文件
        /// </summary>
        /// <param name="infos">列表</param>
        /// <param name="path">路径</param>
        public static void Write(List<Md5Info> infos, string path)
        {
            if (infos == null) return;
            infos.Sort();
            var set = new Md5Set(infos);
            set.Save(path);
        }

        /// <summary>
        /// 和本地清单对比获取升级信息
        /// </summary>
        /// <param name="newDic"></param>
        /// <returns></returns>
        public static UpgInfo GetInfo(Md5Dic newDic)
        {
            return GetInfo(dic, newDic);
        }

        /// <summary>
        /// 获取升级信息
        /// </summary>
        /// <param name="oldDic">旧字典</param>
        /// <param name="newDic">新字典</param>
        /// <returns></returns>
        public static UpgInfo GetInfo(Md5Dic oldDic, Md5Dic newDic)
        {
            var deleted = new List<Md5Info>();
            var changed = new List<Md5Info>();
            var incresed = new List<Md5Info>();
            var nem = newDic.GetEnumerator();
            while (nem.MoveNext())
            {
                var it = nem.Current;
                var key = it.Key;
                var info = it.Value;
                if (oldDic.ContainsKey(key))
                {
                    var lastInfo = oldDic[key];
                    if (lastInfo.MD5.Equals(info.MD5) && lastInfo.Ver == info.Ver) continue;
                    changed.Add(info);
                }
                else
                {
                    incresed.Add(info);
                }
            }

            var oem = oldDic.GetEnumerator();
            while (oem.MoveNext())
            {
                var info = oem.Current;
                if (newDic.ContainsKey(info.Key)) continue;
                deleted.Add(info.Value);
            }
            var upgInfo = new UpgInfo(deleted, changed, incresed);
            return upgInfo;
        }

        /// <summary>
        /// 通过当前等级获取到下一等级段之间的所有资源,all为true:所有高于此等级的资源
        /// </summary>
        /// <param name="cur">等级</param>
        /// <param name="all">all</param>
        /// <returns></returns>
        public static List<Md5Info> GetInfos(int cur, bool all = false)
        {
            var lst = new List<Md5Info>();
            SetInfos(cur, lst, all);
            return lst;
        }

        /// <summary>
        /// 通过当前等级获取到下一等级之间的所有核心资源
        /// </summary>
        /// <param name="cur"></param>
        /// <param name="lst"></param>
        /// <param name="all">all,true下一等级为最高等级</param>
        public static void SetInfos(int cur, List<Md5Info> lst, bool all = false)
        {
            if (md5Set == null)
            {
                Debug.LogError("Loong, mf md5set is null");
            }
            else if (md5Set.infos == null)
            {
                Debug.LogError("Loong, mf md5set.infos is null");
            }
            else if (md5Set.infos.Count < 1)
            {
                Debug.LogError("Loong, mf md5set.infos.count is 0");
            }
            else
            {
                lst.Clear();
                var next = (all ? int.MaxValue : GetNext(cur));
                var min = lvs[0];
                var infos = md5Set.infos;
                int length = infos.Count;
                Md5Info info = null;
                int lv = 0;
                for (int i = 0; i < length; i++)
                {
                    if (isStop)
                    {
                        Debug.LogWarning("Loong,Stop AssetMf SetInfos");
                        break;
                    }
                    info = infos[i];
#if UNITY_ANDROID && SDK_ANDROID_JUNHAI
                    if (App.VerCode > 2340)
                    {
                        if (info.Ver > 0) continue;
                    }
#else
                    if (info.Ver > 0) continue;
#endif
                    lv = info.Lv;
                    if (info.path == UpgUtil.HotfixName) continue;
                    if (lv < min) continue;
                    if (info.Op == 3) continue;
                    if (lv > next) continue;
                    if (!all) if (info.St > -1) continue;
                    lst.Add(info);
                }
            }
        }


        /// <summary>
        /// 通过当前等级获取下一等级段起始等级
        /// </summary>
        /// <param name="cur">当前等级</param>
        /// <returns></returns>
        public static int GetNext(int cur)
        {
            int length = lvs.Count;
            var next = int.MaxValue;
            for (int i = 0; i < length; i++)
            {
                var lv = lvs[i];
                if (lv < cur) continue;
                next = lv; break;
            }
            return next;
        }


        /// <summary>
        /// 获取有效的清单文件路径
        /// </summary>
        /// <returns></returns>
        public static string GetValidPath()
        {
            var path = GetPath(Name);
            if (File.Exists(path))
            {
                var set = new Md5Set();
                if (!set.Read(path))
                {
                    path = null;
                }
            }
            if (path == null)
            {
                path = GetPath(TmpName);
                if (!File.Exists(path))
                {
                    path = null;
                }
            }

            return path;
        }

        /// <summary>
        /// 分包时判断才有意义
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static bool Exist(string name)
        {
#if LOONG_SUB_ASSET
            if (PackDl.Instance.IsOver) return true;
            if (string.IsNullOrEmpty(name)) return false;
            var canDebug = (App.IsDebug || App.IsEditor);
            if (nameDic.ContainsKey(name))
            {
                var info = nameDic[name];
#if UNITY_ANDROID && SDK_ANDROID_JUNHAI
                    if (App.VerCode > 2340)
                    {
                        if (info.Ver > 0) return true;
                    }
#else
                if (info.Ver > 0) return true;
#endif
                if (info.Lv < lvs[0]) return true;
                var op = (AssetOp)info.Op;
                if (op == AssetOp.Verify) return true;
                if (canDebug)
                {
                    iTrace.Warning("Loong", "name:{0} not exist, op:{1},lv:{2},minLv:{3}", name, info.Op, info.Lv, lvs[0]);
                }
            }
            else
            {
                iTrace.Log("Loong", "{0} not exist", name);
            }
            return false;
#else
            return true;
#endif
        }

        public static void StartWatch()
        {
            watch.Reset();
            watch.Start();
        }

        public static void StopWatch()
        {
            watch.Stop();
        }

        public static void Reset(Md5Dic newDic, Md5Set newSet)
        {
            dic = newDic;
            md5Set = newSet;
        }
        #endregion
    }
}