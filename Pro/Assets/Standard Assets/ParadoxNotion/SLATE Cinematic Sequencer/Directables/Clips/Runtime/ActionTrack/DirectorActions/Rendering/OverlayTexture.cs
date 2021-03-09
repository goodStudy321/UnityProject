using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Slate.ActionClips{

    [Category("Rendering")]
    [Description("Displays a texture overlay")]
    public class OverlayTexture : DirectorActionClip {

        [SerializeField] [HideInInspector]
        private float _length = 2;
        [SerializeField] [HideInInspector]
        private float _blendIn = 0.25f;
        [SerializeField] [HideInInspector]
        private float _blendOut = 0.25f;

        public Texture texture;
        [AnimatableParameter]
        public Color color = Color.white;
        [AnimatableParameter]
        public Vector2 scale = Vector2.one;
        [AnimatableParameter]
        public Vector2 position;
        public EaseType interpolation = EaseType.QuadraticInOut;

        /// LY add begin ///
        [SerializeField]
        [AnimatableParameter]
        public bool useRelative = false;

        [AnimatableParameter]
        public Vector2 relativePos = new Vector2(0.5f, 0.5f);

        /// <summary>
        /// 跟随物体
        /// </summary>
        public GameObject followObj = null;
        
        /// LY add end ///

        public override string info{
			get {return string.Format("Overlay '{0}'", texture != null? texture.name : "NONE");}
		}

		public override float length{
			get {return _length;}
			set {_length = value;}
		}

		public override float blendIn{
			get {return _blendIn;}
			set {_blendIn = value;}
		}

		public override float blendOut{
			get {return _blendOut;}
			set {_blendOut = value;}
		}

		protected override void OnUpdate(float deltaTime){
            //// LY edit begin ////

            //var lerpColor = color;
            //lerpColor.a = Easing.Ease(interpolation, 0, color.a, GetClipWeight(deltaTime));
            //DirectorGUI.UpdateOverlayTexture(texture, lerpColor, scale, position);
            
            var lerpColor = color;
            lerpColor.a = Easing.Ease(interpolation, 0, color.a, GetClipWeight(deltaTime));

            if(followObj == null)
            {
                if (useRelative == true)
                {
                    float hfW = Screen.width / 2f;
                    float hfH = Screen.height / 2f;

                    Vector2 pos = Vector2.zero;
                    pos.x = Screen.width * relativePos.x - hfW;
                    pos.y = Screen.height * relativePos.y - hfH;

                    //Vector2 newScale = scale;
                    //newScale.x = newScale.x * ((float)Screen.width / (float)1334);
                    //newScale.y = newScale.y * ((float)Screen.height / (float)750);

                    DirectorGUI.UpdateOverlayTexture(texture, lerpColor, scale, pos, 0);
                }
                else
                {
                    DirectorGUI.UpdateOverlayTexture(texture, lerpColor, scale, position, 0);
                }
            }
            else
            {
                Vector3 sPot = DirectorCamera.current.cam.WorldToScreenPoint(followObj.transform.position);
                float hfW = Screen.width / 2f;
                float hfH = Screen.height / 2f;

                Vector2 pos = Vector2.zero;
                pos.x = sPot.x - hfW + position.x;
                pos.y = sPot.y - hfH + position.y;

                DirectorGUI.UpdateOverlayTexture(texture, lerpColor, scale, pos, 0);
            }

            //// LY edit end ////
        }

        //// LY add begin ////
        
        /// <summary>
        /// 计算texture虚拟深度
        /// </summary>
        /// <returns></returns>
        private int CalTexDepth()
        {
            if(parent == null || parent.parent == null)
            {
                return 0;
            }

            //Debug.Log("----------------------------------------                  :  " + parent.name);
            //Debug.Log("----------------------------------------                              :  " + parent.parent.name);

            CutsceneTrack pT = parent as CutsceneTrack;
            CutsceneGroup pPG = parent.parent as CutsceneGroup;
            List<CutsceneTrack> cutTracks = pPG.tracks;

            int retDepth = 0;
            for(int a = 0; a < cutTracks.Count; a++)
            {
                if(cutTracks[a] == pT)
                {
                    retDepth = a + 1;
                    break;
                }
            }

            return retDepth;
        }

        //// LY add end ////
    }
}
