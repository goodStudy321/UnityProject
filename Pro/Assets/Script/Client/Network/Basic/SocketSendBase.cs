
namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:网络数据发送基类
    /// </summary>
    public abstract class SocketSendBase : SocketBase
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
        /// 发送消息
        /// </summary>
        /// <param name="arr">字节数组</param>
        public abstract void Send(byte[] arr);
        #endregion
    }
}