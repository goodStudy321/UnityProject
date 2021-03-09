#if LOONG_DOWNLOAD_PACKAGE
/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

namespace Loong.Game
{
    /// <summary>
    /// IOS启动安装类
    /// </summary>
    public class IosProcessInstall : IProcessInstall
    {
#region 字段

#endregion

#region 属性

#endregion

#region 构造方法
        public IosProcessInstall()
        {

        }
#endregion

#region 私有方法

#endregion

#region 保护方法

#endregion

#region 公开方法
        public void Start(string path)
        {
            iTrace.Error("Loong", "IOS启动安装未实现");
        }
#endregion
    }
}
#endif