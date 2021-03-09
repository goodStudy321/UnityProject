package phantom.lib;

/**
 * Created by 龙的传人 on 2018/11/22.
 */

public final class App
{
    private static String bsUrl = null;

    /**
     * 获取后台URL
     * @return
     */
    public static String getBSUrl()
    {
        return bsUrl;
    }

    /**
     * 设置后台URL
     * @param val
     */
    public static void setBSUrl(String val)
    {
        bsUrl = val;
    }
}
