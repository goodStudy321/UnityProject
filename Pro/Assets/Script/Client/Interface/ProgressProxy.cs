/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:23
 ============================================================================*/

namespace Loong.Game
{
    using Lang = Phantom.Localization;

    /// <summary>
    /// 进度代理/主线程中无法直接访问Unity对象而通过代理模式进行访问设置
    /// </summary>
    public class ProgressProxy : UIThreadProxy<IProgress>, IProgress
    {
        #region 字段
        private float pro = 0f;

        private int total = 0;

        private int count = 0;

        private string size = null;

        private string tip = null;

        private string msg = null;

        public static readonly ProgressProxy Instance = new ProgressProxy();
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        private ProgressProxy()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Update()
        {
            if (Real == null) return;
            if (tip != null)
            {
                Real.SetTip(tip);
                tip = null;
            }
            if (msg != null)
            {
                Real.SetMessage(msg);
                msg = null;
            }
            if (pro > 0)
            {
                Real.SetProgress(pro);
            }

            if (count > 0)
            {
                Real.SetCount(count);
                count = 0;
            }
            if (total > 0)
            {
                if (size == null) size = "";
                Real.SetTotal(size, total);
                size = null;
                total = 0;
            }

            CheckSetActive();
        }

        public void SetTip(string value)
        {
            tip = value;
        }

        public void SetMessage(string value)
        {
            msg = value;
        }

        public void SetMessage(uint id)
        {
            var msg = Lang.Instance.GetDes(id);
            SetMessage(msg);
        }

        public void SetProgress(float value)
        {
            pro = value;
        }

        public void SetTotal(string size, int total)
        {
            this.size = size;
            this.total = total;
        }

        public void SetCount(int count)
        {
            this.count = count;
        }

        public override void Dispose()
        {
            base.Dispose();
            pro = 0;
            msg = tip = null;
        }
        #endregion
    }



}