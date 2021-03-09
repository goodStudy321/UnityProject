using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using StrDic = System.Collections.Generic.Dictionary<string, string>;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.5
    /// BG:命令行工具
    /// </summary>
    public static class CmdTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #region 参数本身会被分割成两部分,前部分是Key,后部分是Value
        /// <summary>
        /// 解析环境中参数,使用分割符解析每一个参数
        /// </summary>
        /// <param name="split">参数分隔符</param>
        /// <returns>参数字典</returns>
        public static StrDic Parse(char split)
        {
            string[] args = Environment.GetCommandLineArgs();
            return Parse(args, split);
        }

        /// <summary>
        ///  解析命令行参数,使用分割符解析每一个参数
        /// </summary>
        /// <param name="args">所有参数字符,之间使用空格隔开</param>
        /// <param name="split">参数分隔符</param>
        /// <param name="dic">参数字典:为空时创建,反之将参数添加到此字典中</param>
        /// <returns></returns>
        public static StrDic Parse(string arg, char split, StrDic dic = null)
        {
            if (string.IsNullOrEmpty(arg)) return null;
            string[] args = arg.Split(' ');
            return Parse(args, split, dic);
        }

        /// <summary>
        /// 解析命令行参数,使用分割符解析每一个参数
        /// </summary>
        /// <param name="args">参数数组</param>
        /// <param name="split">参数分隔符</param>
        /// <param name="dic">参数字典:为空时创建,反之将参数添加到此字典中</param>
        /// <returns>参数字典</returns>
        public static StrDic Parse(string[] args, char split, StrDic dic = null)
        {
            if (args == null) return null;
            if (args.Length == 0) return null;
            if (dic == null) dic = new StrDic();
            int length = args.Length;
            for (int i = 0; i < length; i++)
            {
                string arg = args[i];
                if (string.IsNullOrEmpty(arg)) continue;
                string[] detail = arg.Split(split);
                string key = detail[0];
                string value = (detail.Length > 1) ? detail[1] : "";
                if (dic.ContainsKey(key)) continue;
                dic.Add(key, value);
            }
            return dic;
        }
        #endregion


        #region 参数与参数之间进行配对,即前一个参数是Key,后一个参数是value
        /// <summary>
        /// 解析环境中参数,通过指定的键值进行配对
        /// </summary>
        /// <param name="keys"></param>
        /// <returns></returns>
        public static StrDic Parse(params string[] keys)
        {
            string[] args = Environment.GetCommandLineArgs();
            return Parse(args, null, keys);
        }

        /// <summary>
        /// 解析命令行参数,通过指定的键值进行配对
        /// </summary>
        /// <param name="arg">参数字符</param>
        /// <param name="dic">参数字典:为空时创建,反之将参数添加到此字典中</param>
        /// <param name="keys">键值列表</param>
        /// <returns></returns>
        public static StrDic Parse(string arg, StrDic dic, params string[] keys)
        {
            if (string.IsNullOrEmpty(arg)) return null;
            string[] args = arg.Split(' ');
            return Parse(args, dic, keys);
        }

        /// <summary>
        /// 解析命令行参数,通过指定的键值进行配对
        /// </summary>
        /// <param name="args">参数数组</param>
        /// <param name="keys">键值列表</param>
        /// <returns></returns>
        public static StrDic Parse(string[] args, StrDic dic, params string[] keys)
        {
            if (args == null) return null;
            if (args.Length == 0) return null;
            if (keys == null) return null;
            if (keys.Length == 0) return null;
            if (dic == null) dic = new StrDic();
            int keyLen = keys.Length;
            for (int i = 0; i < keyLen; i++)
            {
                string key = keys[i];
                if (dic.ContainsKey(key)) continue;
                dic.Add(key, "");
            }

            int argLen = args.Length;
            for (int i = 0; i < argLen; i++)
            {
                string curArg = args[i];
                if (!dic.ContainsKey(curArg)) continue;
                string nextArg = "";
                int nextIdx = i + 1;
                if (nextIdx < argLen) nextArg = args[nextIdx];
                if (dic.ContainsKey(nextArg)) continue;
                dic[curArg] = nextArg;
            }

            return dic;
        }
        #endregion

        /// <summary>
        /// 将参数字典转换为字符串
        /// </summary>
        /// <param name="argDic"></param>
        /// <returns></returns>
        public static string GetString(StrDic argDic)
        {
            if (argDic == null || argDic.Count == 0) return "None";
            StringBuilder sb = new StringBuilder();
            foreach (KeyValuePair<string, string> item in argDic)
            {
                sb.Append(" <").Append(item.Key).Append(",");
                sb.Append(item.Value).Append(">");
            }
            string str = sb.ToString();
            return str;
        }
        #endregion
    }
}