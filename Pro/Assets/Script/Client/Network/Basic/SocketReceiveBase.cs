namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:网络数据接收接口
    /// </summary>
    public abstract class SocketReceiveBase : SocketBase
    {
        #region 字段
        private bool running = false;

        #endregion

        #region 属性

        public bool Running
        {
            get
            {
                return running;
            }
            set
            {
                running = value;
            }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 接收数据
        /// </summary>
        public abstract void Receive();

        #endregion
    }
}