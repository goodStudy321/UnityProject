using System;
using UnityEngine;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;
using Object = UnityEngine.Object;

namespace Hello.Game
{
    public class ElapsedTime 
    {
        private Stopwatch sw = new Stopwatch();

        public TimeSpan Elapsed
        {
            get
            {
                return sw.Elapsed;
            }
        }

        public void Beg()
        {
            sw.Reset();
            sw.Start();
        }

        public void End()
        {
            sw.Stop();
        }

        public void End(string fmt,params object[] args)
        {
            sw.Stop();
            if (fmt == null) fmt = "";
            var tip = string.Format(fmt, args);
            Debug.LogWarningFormat("Hello,{0} elapsed time:{1}", tip, sw.Elapsed);
        }
    }
}


