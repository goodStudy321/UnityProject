/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 17:34:13
 ============================================================================*/

using System;
using System.IO;
using System.Net;

namespace Loong.Game
{
    /// <summary>
    /// 通用上传
    /// </summary>
    public class GenericUpload : IUpload
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public GenericUpload()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public bool Upload(string sourceURI, string targetURI, Action<float> progress)
        {
            bool success = true;

            FileStream sourceFileStream = new FileStream(sourceURI, FileMode.Open, FileAccess.Read);
            BinaryReader br = new BinaryReader(sourceFileStream);
            Uri svrURI = new Uri(targetURI);
#if NET_2_0_SUBSET
            var httpReq = (HttpWebRequest)HttpWebRequest.Create(svrURI);
#else
            var httpReq = (HttpWebRequest)HttpWebRequest.Create(svrURI);
#endif
            httpReq.KeepAlive = false;
            //httpReq.Credentials = new NetworkCredential("用户名", "密码");
            httpReq.Method = WebRequestMethods.Http.Post;
            //对发送的数据不使用缓存
            httpReq.AllowWriteStreamBuffering = false;
            //设置获得响应的超时时间100秒
            httpReq.Timeout = 100000;

            long fileLength = sourceFileStream.Length;
            httpReq.ContentLength = fileLength;
            float totalSize = fileLength;

            Stream postStream = null;
            try
            {
                //每次上传2K
                int bufLength = 2048;
                byte[] buf = new byte[bufLength];
                //已经上传的字节数
                long offset = 0;

                //DateTime startTime = DateTime.Now;
                //StringBuilder sb = new StringBuilder();


                postStream = httpReq.GetRequestStream();
                int size = br.Read(buf, 0, buf.Length);
                while (size > 0)
                {

                    postStream.Write(buf, 0, size);

                    offset += size;
                    if (progress != null) progress(size / totalSize);
                    #region 计算上传速度
                    //sb.Remove(0, sb.Length);
                    //TimeSpan span = DateTime.Now - startTime;
                    ////已用时/秒
                    //double seconds = span.TotalSeconds;

                    //if (seconds > 0.001)
                    //{
                    //    sb.Append("已用时:").Append(seconds).Append("秒");
                    //    sb.Append("平均速度:").Append(offset / 1024 / seconds).Append("KB/秒");
                    //}
                    //else
                    //{
                    //    sb.Append("正在玩命加载中···");
                    //}
                    //Debug.Log("Loong:\t" + sb.ToString());
                    #endregion

                    size = br.Read(buf, 0, buf.Length);

                }

                #region 服务器响应 判断是否写入成功
                WebResponse res = httpReq.GetResponse();
                Stream stream = res.GetResponseStream();
                StreamReader read = new StreamReader(stream);
                string result = read.ReadToEnd();
                if (!result.Equals("Success")) success = false;
                read.Dispose();
                stream.Dispose();

                res.Close();

                if (progress != null) progress(size / totalSize);
                #endregion
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", string.Format("上传文件错误:{0},路径:{1}", e.Message, targetURI));
                success = false;
            }
            finally
            {
                if (br != null) br.Close();
                if (sourceFileStream != null) sourceFileStream.Dispose();
                if (postStream != null) postStream.Dispose();
            }

            return success;
        }
        #endregion
    }
}