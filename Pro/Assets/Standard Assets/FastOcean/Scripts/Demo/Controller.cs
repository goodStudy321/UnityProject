using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using System.Text;
using UnityEngine.Profiling;

namespace FastOcean
{
	public abstract class Controller : MonoBehaviour
	{
	    public UI ui = null;

        public float updateInterval = 1.5f;
        protected float timeleft;
        protected float fpsUpdate = 0.0f;

        protected StringBuilder sb = new StringBuilder(512);
		protected bool UpdateGUI(FOceanGrid grid) 
        {
            if (ui == null)
                return false;

            if (ui.info == null)
                return false;

            if (Input.GetKey(KeyCode.Return))
                ui.OnClickNextScene();

            if (timeleft <= 0.0f)
            {
                fpsUpdate = 1 / Time.smoothDeltaTime;
                timeleft = updateInterval;

                sb.Length = 0;
                sb.AppendLine("Version: " + FOcean.version);
                sb.AppendLine("GraphicsDeviceType: " + SystemInfo.graphicsDeviceType);
                sb.AppendLine("GraphicsDeviceName: " + SystemInfo.graphicsDeviceName);
                sb.AppendLine("Resolution: " + Screen.width + "x" + Screen.height);
                if (FOcean.instance != null)
                    sb.AppendLine("SupportSM3: " + FOcean.instance.supportSM3);
                sb.AppendLine("TextureLimit: " + QualitySettings.masterTextureLimit.ToString());
                sb.AppendLine("AntiAliasing: " + QualitySettings.antiAliasing.ToString());
                sb.AppendLine("AnisFiltering: " + QualitySettings.anisotropicFiltering.ToString());
                sb.AppendLine("ColorSpace: " + QualitySettings.activeColorSpace.ToString());
                sb.AppendLine("AmbientSource: " + RenderSettings.ambientMode.ToString());
                sb.AppendLine("FPS: " + fpsUpdate.ToString("f2"));
                sb.AppendLine("GridSize: " + grid.baseParam.usedGridSize);
                sb.AppendLine("AllocatedMemory(KB): " + (Profiler.GetTotalAllocatedMemoryLong() >> 10));
                sb.AppendLine("ReservedMemory(KB): " + (Profiler.GetTotalReservedMemoryLong() >> 10));

                ui.info.text = sb.ToString();
                
                Application.targetFrameRate = -1;

                return true;
            }

            timeleft -= Time.deltaTime;

            return false;
        }
	}
}