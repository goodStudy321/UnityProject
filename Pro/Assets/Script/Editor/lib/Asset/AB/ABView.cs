using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Hello.Edit
{
    public class ABView : EditViewBase
    {
        [SerializeField]
        [HideInInspector]
        private bool abForce = false;

        [SerializeField]
        [HideInInspector]
        private bool compress = false;

        [SerializeField]
        [HideInInspector]
        private string output = "../Assets";

        [SerializeField]
        [HideInInspector]
        private readonly List<string> originSfxs = new List<string>();

        public bool AbForce { get { return abForce; } }

        public bool Compress { get { return compress; } }

        public string OutPut
        {
            get
            {
                if (string.IsNullOrEmpty(output))
                {
                    output = "../Assets";
                    SetOutput();
                }
                return output;
            }
        }

        private void SetOutput()
        {
            output = Path.GetFullPath(output);
            output.Replace("\\", "/");
        }

    }

}

