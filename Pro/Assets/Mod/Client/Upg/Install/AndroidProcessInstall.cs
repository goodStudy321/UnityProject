#if LOONG_DOWNLOAD_PACKAGE
/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

namespace Loong.Game
{
    /// <summary>
    /// 安卓启动安装类
    /// </summary>
    public class AndroidProcessInstall : IProcessInstall
    {
#region 字段

#endregion

#region 属性

#endregion

#region 构造方法
        public AndroidProcessInstall()
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
            iTrace.Error("Loong", "Android启动安装未实现");
        }
#endregion
    }
}
#endif