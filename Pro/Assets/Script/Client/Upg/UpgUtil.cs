/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System.IO;
using System.Text;
using System.Collections.Generic;

namespace Loong.Game
{
    using Md5Dic = Dictionary<string, Md5Info>;
    /// <summary>
    /// 升级工具
    /// </summary>
    public static class UpgUtil
    {
        #region 字段
        private static string compDir = null;

        private static string decompDir = null;

        /// <summary>
        /// 安装包版本号文件名称
        /// </summary>
        public const string PkgVerFile = "AppVer.txt";

        /// <summary>
        /// 资源版本号文件名称
        /// </summary>
        public const string AssetVerFile = "AssetVer.txt";

        /// <summary>
        /// 升级失败信息文件名称
        /// </summary>
        public const string FailFile = "UpgFail.xml";

        /// <summary>
        /// 远程路径,结尾要有正斜杠
        /// </summary>
        //public const string Host = "http://test.korea.cdn.phantom-u3d001.com/";
        public const string Host = "https://haneul-cdn.withhug.kr/";
        //public const string Host = "http://cdn.zl.phantom-u3d001.com/";

        /// <summary>
        /// 远程根目录,结尾要有正斜杠
        /// </summary>
        public const string URL = Host + "td1_2019_and_hg/";
        //public const string URL = Host + "td1_and_zl/";

        /// <summary>
        /// CS更新文件
        /// </summary>
        public const string HotfixName = "png.bytes";

        #endregion

        #region 属性

        /// <summary>
        /// 压缩文件目录
        /// </summary>
        public static string CompDir
        {
            get { return compDir; }
        }

        /// <summary>
        /// 解压文件目录
        /// </summary>
        public static string DecompDir
        {
            get { return decompDir; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public static void Init()
        {
            var persist = AssetPath.Persistent;
            compDir = string.Format("{0}/Comp/", persist);
            decompDir = string.Format("{0}/Decomp/", persist);
            DirUtil.Check(compDir);
            DirUtil.Check(decompDir);
        }

        /// <summary>
        /// 根据索引获取压缩包名称
        /// </summary>
        public static string GetZipName(int idx)
        {
            string name = string.Format("Assets{0}.zip", idx);
            return name;
        }

        /// <summary>
        /// 获取本地文件路径
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static string GetLocalPath(string path)
        {
            return string.Format("{0}/{1}", AssetPath.Persistent, path);
        }

        /// <summary>
        /// 获取压缩文件路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetCompPath(string name)
        {
            var path = compDir + name;
            return path;
        }

        /// <summary>
        /// 通过MD5信息获取压缩文件路径
        /// </summary>
        /// <param name="info"></param>
        /// <returns></returns>
        public static string GetCompPath(Md5Info info)
        {
            var path = info.path + info.MD5;
            path = compDir + path;
            return path;
        }

        /// <summary>
        /// 获取解压文件路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetDecompPath(string name)
        {
            var path = decompDir + name;
            return path;
        }

        /// <summary>
        /// 通过MD5信息获取解压文件路径
        /// </summary>
        /// <param name="info"></param>
        /// <returns></returns>
        public static string GetDecompPath(Md5Info info)
        {
            var path = info.path + info.MD5;
            path = decompDir + path;
            return path;
        }

        /// <summary>
        /// 获取失败清单文件路径
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetFailPath()
        {
            return string.Format("{0}{1}", AssetPath.Cache, FailFile);
        }

        /// <summary>
        /// 删除失败清单文件
        /// </summary>
        /// <returns></returns>
        public static void DeleteFail()
        {
            var path = GetFailPath();
            FileTool.SafeDelete(path);
        }

        /// <summary>
        /// 获取指定目录的远程路径
        /// </summary>
        /// <param name="url"></param>
        /// <param name="folder">文件夹</param>
        /// <returns></returns>
        public static string GetUrl(string url, string folder)
        {
            var sb = new StringBuilder();
            sb.Append(url).Append("/");
            sb.Append(AssetPath.Platform).Append("/");
            sb.Append(folder).Append("/");
            var path = sb.ToString();
            return path;
        }

        /// <summary>
        /// 获取网络异常描述
        /// </summary>
        /// <returns></returns>
        public static uint GetCheckNetDes()
        {
            return 617008;
        }

        /// <summary>
        /// 获取版本号错误描述
        /// </summary>
        /// <returns></returns>
        public static uint GetVerFailDes()
        {
            return 617009;
        }


        #endregion
    }
}