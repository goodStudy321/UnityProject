using System.IO;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.20
    /// BG:后缀名类/全小写
    /// </summary>
    public static class Suffix
    {
        #region 字段
        /// <summary>
        /// 无
        /// </summary>
        public const string None = "none";
        /// <summary>
        /// 场景资源后缀名
        /// </summary>
        public const string Scene = ".unity";
        /// <summary>
        /// Shader后缀名
        /// </summary>
        public const string Shader = ".shader";

        /// <summary>
        /// 图片png格式
        /// </summary>
        public const string Png = ".png";
        /// <summary>
        /// 图片jpg格式
        /// </summary>
        public const string Jpg = ".jpg";
        /// <summary>
        /// 图片tga格式
        /// </summary>
        public const string Tga = ".tga";
        /// <summary>
        /// 图片psd格式
        /// </summary>
        public const string Psd = ".psd";
        /// <summary>
        /// 材质后缀名
        /// </summary>
        public const string Mat = ".mat";
        /// <summary>
        /// 物理材质
        /// </summary>
        public const string PhysicMat = ".physicmaterial";

        /// <summary>
        /// 动画片段后缀名
        /// </summary>
        public const string Animation = ".anim";
        /// <summary>
        /// 动画控制器后缀名
        /// </summary>
        public const string Animator = ".controller";
        /// <summary>
        /// 动画肌肉遮罩
        /// </summary>
        public const string AvatarMask = ".mask";

        /// <summary>
        /// 字体设置后缀
        /// </summary>
        public const string Font = ".fontsetting";
        /// <summary>
        /// OTF字体
        /// </summary>
        public const string OTF = ".otf";
        /// <summary>
        /// TTF字体
        /// </summary>
        public const string TTF = ".ttf";
        /// <summary>
        /// GUI皮肤后缀
        /// </summary>
        public const string GUISkin = ".skin";

        /// <summary>
        /// 3DMax到处的模型后缀名
        /// </summary>
        public const string Fbx = ".fbx";
        /// <summary>
        /// 玛雅到处的模型后缀名
        /// </summary>
        public const string Mb = ".mb";
        /// <summary>
        /// 预制件后缀名
        /// </summary>
        public const string Prefab = ".prefab";

        /// <summary>
        /// 音乐WAV格式后缀名
        /// </summary>
        public const string Wav = ".wav";
        /// <summary>
        /// MP3格式后缀名
        /// </summary>
        public const string Mp3 = ".mp3";
        /// <summary>
        /// Ogg格式后缀名
        /// </summary>
        public const string Ogg = ".ogg";

        /// <summary>
        /// 光照贴图后缀名
        /// </summary>
        public const string Exr = ".exr";
        /// <summary>
        /// 通用资源后缀名
        /// </summary>
        public const string Asset = ".asset";

        /// <summary>
        /// AB后缀名
        /// </summary>
        public const string AB = ".ab";
        /// <summary>
        /// CSharp文件后缀名
        /// </summary>
        public const string CS = ".cs";
        /// <summary>
        /// Lua脚本文件后缀名
        /// </summary>
        public const string Lua = ".lua";
        /// <summary>
        /// JavaScript文件后缀名
        /// </summary>
        public const string Js = ".js";

        /// <summary>
        /// 压缩文件后缀名
        /// </summary>
        public const string Zip = ".zip";

        /// <summary>
        /// 元数据文件后缀名
        /// </summary>
        public const string Meta = ".meta";

        /// <summary>
        /// 清单文件后缀名
        /// </summary>
        public const string Manifest = ".manifest";

        /// <summary>
        /// 纯文本文件后缀名
        /// </summary>
        public const string Txt = ".txt";

        /// <summary>
        /// Json文件后缀名
        /// </summary>
        public const string Json = ".json";

        /// <summary>
        /// Xml文件后缀名
        /// </summary>
        public const string Xml = ".xml";

        /// <summary>
        /// 二进制资源
        /// </summary>
        public const string Bytes = ".bytes";
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
        /// <summary>
        /// 获取纯小写的后缀名
        /// </summary>
        /// <param name="filePath">文件路径</param>
        /// <returns></returns>
        public static string Get(string filePath)
        {
            if (string.IsNullOrEmpty(filePath)) return null;
            string sfx = Path.GetExtension(filePath);
            sfx = sfx.ToLower();
            return sfx;
        }
        #endregion
    }
}