package phantom.lib;

/**
 * Created by 龙的传人 on 2018/3/13.
 * 字符串工具
 */

public final class StrTool
{
    /**
     * 判断字符串是否为空
     *
     * @param str 字符串
     * @return true:是
     */
    public static boolean isEmpty(String str)
    {
        if (str == null) return true;
        if (str.length() < 1) return true;
        return false;
    }
}
