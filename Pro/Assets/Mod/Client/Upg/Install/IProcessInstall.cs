#if LOONG_DOWNLOAD_PACKAGE
/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

namespace Loong.Game
{
    /// <summary>
    /// 启动安装接口
    /// </summary>
    public interface IProcessInstall
    {
        void Start(string path);
    }
}
#endif