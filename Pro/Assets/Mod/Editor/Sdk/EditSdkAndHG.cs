#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    public class EditSdkAndHG : EditAndroidSdk
    {
#if SDK_ANDROID_HG
        public override string Des
        {
            get { return "hg_google"; }
        }
#endif

#if SDK_ONESTORE_HG
        public override string Des
        {
            get { return "hg_onestore"; }
        }
#endif

#if SDK_SAMSUNG_HG
        public override string Des
        {
            get { return "hg_samsung"; }
        }
#endif

#if SDK_ANDROID_HG
        public override string BundleID
        {
            get { return "com.monawa.haneul"; }
        }

        public override string AppName => "하늘무사";
#endif

#if SDK_ONESTORE_HG
        public override string BundleID
        {
            get { return "com.monawa.haneulone"; }
        }

        public override string AppName => "하늘무사";
#endif

#if SDK_SAMSUNG_HG
        public override string BundleID
        {
            get { return "com.monawa.haneulsam"; }
        }

        public override string AppName => "하늘무사";
#endif


#if SDK_ANDROID_HG
        public override string StoreName
        {
            get { return SdkUtil.GetCfgPath(Des, "PhantomSLRPGA.jks"); }
        }

        public override string StorePass => "Phantom2017forever86SLRPGA";

        public override string AliasName => "PhantomSLARPGA";

        public override string AliasPass => "Phantom2017forever86SLRPGA";
#endif

#if SDK_ONESTORE_HG
        public override string StoreName
        {
            get { return SdkUtil.GetCfgPath(Des, "PhantomSLRPGA.jks"); }
        }

        public override string StorePass => "Phantom2017forever86SLRPGA";

        public override string AliasName => "PhantomSLARPGA";

        public override string AliasPass => "Phantom2017forever86SLRPGA";
#endif

#if SDK_SAMSUNG_HG
        public override string StoreName
        {
            get { return SdkUtil.GetCfgPath(Des, "PhantomSLRPGA.jks"); }
        }

        public override string StorePass => "Phantom2017forever86SLRPGA";

        public override string AliasName => "PhantomSLARPGA";

        public override string AliasPass => "Phantom2017forever86SLRPGA";
#endif

        public override void Beg(Dictionary<string, string> dic)
        {
            base.Beg(dic);
        }
    }
}
#endif

