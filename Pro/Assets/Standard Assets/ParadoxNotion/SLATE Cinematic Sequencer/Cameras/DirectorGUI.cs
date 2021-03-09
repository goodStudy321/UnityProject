using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

namespace Slate{

    //// LY add begin ////
    
    /// <summary>
    /// 图片信息结构
    /// </summary>
    public class TexInfo
    {
        public Texture overlayTexture = null;
        public Color overlayTextureColor = Color.white;
        public Vector2 overlayTextureScale = Vector2.one;
        public Vector2 overlayTexturePosition = Vector2.one;
        public int depth = 0;
    }

    /// <summary>
    /// 文字信息结构
    /// </summary>
    public class TextInfo
    {
        public ActionClip owner = null;
        public string overlayText = "";
        public Color overlayTextColor = Color.white;
        public float overlayTextSize = 26;
        public TextAnchor overlayTextAnchor = TextAnchor.MiddleCenter;
        public Vector2 overlayTextPos = Vector2.zero;
        public int depth = 0;
    }

    //// LY add end ////

    [ExecuteInEditMode]
	///Handles subtitles, fades, crossfades etc.
	public class DirectorGUI : MonoBehaviour {

		//Exposed styling parameters
		public Font subtitlesFont;
		public Font overlayTextFont;

        // LY edit begin //

        //Constant styling parameters
        //private const float CINEBOX_SIZE = 20f;
        //private const float SUBS_SIZE    = 18f;

        [SerializeField]
        public float CINEBOX_SIZE_UP = 20f;
        [SerializeField]
        public float CINEBOX_SIZE_DOWN = 40;
        [SerializeField]
        public Color CINEBOX_COLOR = new Color(0.05f, 0.05f, 0.05f, 1f);
        [SerializeField]
        public float SUBS_SIZE = 24f;                                       /* 字幕字体大小 */
        [SerializeField]
        public Vector2 SUBS_OFFSET = Vector2.zero;                          /* 字幕偏移 */
        [SerializeField]
        public bool BOLD = true;                                            /* 粗体 */
        [SerializeField]
        public bool ITALIC = false;                                         /* 斜体 */

        // LY edit end //

        //EVENT DELEGATES
        public delegate void SubtitlesGUIDelegate(string text, Color color);
		public delegate void TextOverlayGUIDelegate(string text, Color color, float size, TextAnchor alignment, Vector2 position);
		public delegate void TextureOverlayGUIDelegate(Texture texture, Color color, Vector2 position, Vector2 scale);
		public delegate void ScreenFadeGUIDelegate(Color color);
		public delegate void LetterboxGUIDelegate(float completion);

		///EVENTS
		///Subscribe to any of these events to handle the UI manualy for that element and override the default GUI.
		public static event SubtitlesGUIDelegate OnSubtitlesGUI;
		public static event TextOverlayGUIDelegate OnTextOverlayGUI;
		public static event TextureOverlayGUIDelegate OnTextureOverlayGUI;
		public static event ScreenFadeGUIDelegate OnScreenFadeGUI;
		public static event LetterboxGUIDelegate OnLetterboxGUI;

		public static event Action OnGUIEnable;
		public static event Action OnGUIDisable;
		public static event Action OnGUIUpdate;
		///


		[NonSerialized]
		private static DirectorGUI _current;
		public static DirectorGUI current{
			get
			{
				if (_current == null){
					_current = FindObjectOfType<DirectorGUI>();
					//add component on director camera gameobject purely for organization purposes.
					if (_current == null && DirectorCamera.current != null){
						_current = DirectorCamera.current.gameObject.GetAddComponent<DirectorGUI>();
					}
				}
				return _current;
			}
		}


		private static GUIStyle subsStyle{ get; set; }
		private static GUIStyle overlayTextStyle{ get; set; }

		///...
		void Awake(){
			if (_current != null && _current != this){
				DestroyImmediate(this);
				return;
			}

			_current = this;
		}

		///init styles
		void OnEnable(){

			//subs style
			subsStyle = new GUIStyle();
			subsStyle.normal.textColor = Color.white;
			subsStyle.richText = true;
			subsStyle.padding = new RectOffset(10,10,2,2);
			subsStyle.alignment = TextAnchor.LowerCenter;
			subsStyle.font = subtitlesFont;

			//overlay text style
			overlayTextStyle = new GUIStyle();
			overlayTextStyle.normal.textColor = Color.white;
			overlayTextStyle.richText = true;
			overlayTextStyle.font = overlayTextFont;

            //// LY add begin ////

            tipStyle = new GUIStyle();
            tipStyle.normal.textColor = Color.white;
            tipStyle.richText = true;
            tipStyle.font = overlayTextFont;

            //// LY add end ////


            if (OnGUIEnable != null){
				OnGUIEnable();
			}
		}

		///Reset values whenever disabled. Thus for example fading out from a cutscene, the next cutscene does not remain faded.
		void OnDisable(){
			UpdateDissolve(null, 0);
			UpdateLetterbox(0);
			UpdateFade(Color.clear);
			UpdateSubtitles(null, Color.clear);

            //// LY edit begin ////
			//UpdateOverlayText(null, Color.clear, 0, default(TextAnchor), Vector2.zero);
            ClearOverlayText();
            //// LY edit end ////

            //// LY edit begin ////
            //UpdateOverlayTexture(null, Color.clear, Vector2.zero, Vector2.zero);
            ClearOverlayTexture();
            //// LY edit end ////

            if (OnGUIDisable != null){
				OnGUIDisable();
			}
		}


		[NonSerialized] private static Texture dissolver;
		[NonSerialized] private static float dissolveCompletion;
		public static void UpdateDissolve(Texture texture, float completion){
			if (current != null){
				dissolver = texture;
				dissolveCompletion = completion;
			}
		}


		[NonSerialized] private static float letterboxCompletion;
		public static void UpdateLetterbox(float completion){
			if (OnLetterboxGUI != null){
				OnLetterboxGUI(completion);
				return;
			}
			if (current != null){
				letterboxCompletion = completion;
			}
		}


		[NonSerialized] public static Color fadeColor;
		public static void UpdateFade(Color color){
			if (OnScreenFadeGUI != null){
				OnScreenFadeGUI(color);
				return;
			}
			if (current != null){
				fadeColor = color;
			}
		}


		[NonSerialized] private static string subsText;
		[NonSerialized] private static Color subsColor;
		public static void UpdateSubtitles(string text, Color color){
			if (OnSubtitlesGUI != null){
				OnSubtitlesGUI(text, color);
				return;
			}
			if (current != null){
				subsText = text;
			}
			subsColor = color;
		}

        //// LY edit begin ////

        //[NonSerialized] private static string overlayText;
        //[NonSerialized] private static Color overlayTextColor;
        //[NonSerialized] private static float overlayTextSize;
        //[NonSerialized] private static TextAnchor overlayTextAnchor;
        //[NonSerialized] private static Vector2 overlayTextPos;

        [NonSerialized] private static List<TextInfo> overlayTextInfos = new List<TextInfo>();

        //      public static void UpdateOverlayText(string text, Color color, float size, TextAnchor anchor, Vector2 pos){
        //	if (OnTextOverlayGUI != null){
        //		OnTextOverlayGUI(text, color, size, anchor, pos);
        //		return;
        //	}
        //	if (current != null){
        //		overlayText = text;
        //		overlayTextColor = color;
        //		overlayTextSize = size;
        //		overlayTextAnchor = anchor;
        //		overlayTextPos = pos;
        //	}
        //}

        public static void UpdateOverlayText(ActionClip aClip, string text, Color color, float size, TextAnchor anchor, Vector2 pos, int depth = 0)
        {
            if (OnTextOverlayGUI != null)
            {
                OnTextOverlayGUI(text, color, size, anchor, pos);
                return;
            }
            if (current != null)
            {
                AddOverlayText(aClip, text, color, size, anchor, pos, depth);
            }
        }

        public static void ClearOverlayText()
        {
            overlayTextInfos.Clear();
        }

        private static TextInfo CheckOverlayTextExist(ActionClip aClip)
        {
            TextInfo retInfo = null;
            for (int a = 0; a < overlayTextInfos.Count; a++)
            {
                if (overlayTextInfos[a].owner == aClip)
                {
                    retInfo = overlayTextInfos[a];
                    break;
                }
            }

            return retInfo;
        }

        private static void AddOverlayText(ActionClip aClip, string text, Color color, float size, TextAnchor anchor, Vector2 pos, int depth = 0)
        {
            TextInfo doText = CheckOverlayTextExist(aClip);
            if (doText == null)
            {
                doText = new TextInfo();
                doText.owner = aClip;
                overlayTextInfos.Add(doText);
            }
            doText.overlayText = text;
            doText.overlayTextColor = color;
            doText.overlayTextSize = size;
            doText.overlayTextAnchor = anchor;
            doText.overlayTextPos = pos;
            doText.depth = depth;
        }

        private static void RemoveOverlayText(ActionClip aClip)
        {
            TextInfo removeText = CheckOverlayTextExist(aClip);
            if (removeText != null)
            {
                overlayTextInfos.Remove(removeText);
            }
        }

        //// LY edit end ////

        //// LY edit begin ////

        //[NonSerialized] private static Texture overlayTexture;
        //[NonSerialized] private static Color overlayTextureColor;
        //[NonSerialized] private static Vector2 overlayTextureScale;
        //[NonSerialized] private static Vector2 overlayTexturePosition;

        [NonSerialized] private static List<TexInfo> overlayTexInfos = new List<TexInfo>();

        private static TexInfo CheckOverlayTexExist(Texture texture)
        {
            TexInfo retInfo = null;
            for(int a = 0; a < overlayTexInfos.Count; a++)
            {
                if(overlayTexInfos[a].overlayTexture == texture)
                {
                    retInfo = overlayTexInfos[a];
                    break;
                }
            }

            return retInfo;
        }

        private static void AddOverlayTex(Texture texture, Color color, Vector2 scale, Vector2 positionOffset, int depth = 0)
        {
            TexInfo doTex = CheckOverlayTexExist(texture);
            if (doTex == null)
            {
                doTex = new TexInfo();
                doTex.overlayTexture = texture;
                overlayTexInfos.Add(doTex);
            }
            doTex.overlayTextureColor = color;
            doTex.overlayTextureScale = scale;
            doTex.overlayTexturePosition = positionOffset;
            doTex.depth = depth;
        }

        private static void RemoveOverlayTex(Texture texture)
        {
            TexInfo removeTex = CheckOverlayTexExist(texture);
            if(removeTex != null)
            {
                overlayTexInfos.Remove(removeTex);
            }
        }

        //// LY edit end ////

        //// LY edit begin ////
        
  //      public static void UpdateOverlayTexture(Texture texture, Color color, Vector2 scale, Vector2 positionOffset){
		//	if (OnTextureOverlayGUI != null){
		//		OnTextureOverlayGUI(texture, color, scale, positionOffset);
		//		return;
		//	}
		//	if (current != null){
		//		overlayTexture = texture;
		//		overlayTextureColor = color;
		//		overlayTextureScale = scale;
		//		overlayTexturePosition = positionOffset;
		//	}
		//}

        public static void UpdateOverlayTexture(Texture texture, Color color, Vector2 scale, Vector2 positionOffset, int depth)
        {
            if (OnTextureOverlayGUI != null)
            {
                OnTextureOverlayGUI(texture, color, scale, positionOffset);
                return;
            }
            if (current != null)
            {
                AddOverlayTex(texture, color, scale, positionOffset, depth);
            }
        }

        public static void ClearOverlayTexture()
        {
            overlayTexInfos.Clear();
        }

        //// LY edit end ////

        //The order is obviously important
        void OnGUI(){

			if (dissolver != null ){
				DoDissolve();
			}

			if (letterboxCompletion > 0){
				DoLetterbox();
			}

			if (fadeColor.a > 0){
				DoFade();
			}

            //// LY edit begin ////
            //if (overlayTextureColor.a > 0 && overlayTexture != null){
            //	DoOverlayTexture();
            //}
            DoOverlayTexture();
            //// LY edit end ////

            if (subsColor.a > 0 && !string.IsNullOrEmpty(subsText)){
				DoSubs();
			}

            //// LY edit begin ////
            //if (overlayTextColor.a > 0 && !string.IsNullOrEmpty(overlayText) ){
            //	DoOverlayText();
            //}
            DoOverlayText();
            //// LY edit end ////

            //// LY add begin ////
            OnTipsUpdate();
            //// LY add end ////

#if UNITY_EDITOR
            if (!Application.isPlaying && Prefs.showRuleOfThirds){
				DoRuleOfThirds();
			}
			#endif

			if (OnGUIUpdate != null){
				OnGUIUpdate();
			}

		}


		///Dissolving
		void DoDissolve(){
			var rect = new Rect(0, 0, Screen.width, Screen.height);
			GUI.color = new Color(1, 1, 1, 1- dissolveCompletion);
			GUI.DrawTexture(rect, dissolver);
			GUI.color = Color.white;
		}

		
		///Letterbox
		void DoLetterbox(){

            // LY edit begin //

            //var a = new Rect(0, 0, Screen.width, CINEBOX_SIZE);
            //var b = new Rect(0, 0, Screen.width, CINEBOX_SIZE);

            //var lerp = Easing.Ease(EaseType.QuadraticInOut, 0, 1, letterboxCompletion);
            //a.y = Mathf.Lerp(-CINEBOX_SIZE, 0, lerp);
            //b.y = Mathf.Lerp(Screen.height, Screen.height - CINEBOX_SIZE, lerp);

            //GUI.color = new Color(0.05f, 0.05f, 0.05f, letterboxCompletion);
            //GUI.DrawTexture(a, Texture2D.whiteTexture);
            //GUI.DrawTexture(b, Texture2D.whiteTexture);
            //GUI.color = Color.white;

            var a = new Rect(0, 0, Screen.width, CINEBOX_SIZE_UP);
            var b = new Rect(0, 0, Screen.width, CINEBOX_SIZE_DOWN);

            var lerp = Easing.Ease(EaseType.QuadraticInOut, 0, 1, letterboxCompletion);
            a.y = Mathf.Lerp(-CINEBOX_SIZE_UP, 0, lerp);
            b.y = Mathf.Lerp(Screen.height, Screen.height - CINEBOX_SIZE_DOWN, lerp);

            CINEBOX_COLOR.a = letterboxCompletion;
            GUI.color = CINEBOX_COLOR;
            GUI.DrawTexture(a, Texture2D.whiteTexture);
            GUI.DrawTexture(b, Texture2D.whiteTexture);
            GUI.color = Color.white;

            // LY edit end //
        }


        ///Fading
        void DoFade(){
			var rect = new Rect(0, 0, Screen.width, Screen.height);
			GUI.color = fadeColor;
			GUI.DrawTexture(rect, Texture2D.whiteTexture);
			GUI.color = Color.white;
		}

		void DoSubs(){

            // LY edit begin //

            //var finalSubs = string.Format("<size={0}><b><i>{1}</i></b></size>", SUBS_SIZE, subsText);
            //var size = subsStyle.CalcSize(new GUIContent(finalSubs));
            //var rect = new Rect(0, 0, size.x, size.y);
            //rect.center = new Vector2(Screen.width/2, Screen.height - (size.y/2) - 12);
            //GUI.color = new Color(0,0,0, Mathf.Lerp(0, 0.2f, subsColor.a));
            //GUI.DrawTexture(rect, Texture2D.whiteTexture);

            //rect.center -= new Vector2(2,-2);
            //GUI.color = new Color(0,0,0,subsColor.a);
            //GUI.Label(rect, finalSubs, subsStyle);
            //rect.center += new Vector2(2,-2);

            //GUI.color = subsColor;
            //GUI.Label(rect, finalSubs, subsStyle);
            //GUI.color = Color.white;


            string finalSubs = "";
            if(BOLD == true && ITALIC == true)
            {
                finalSubs = string.Format("<size={0}><b><i>{1}</i></b></size>", SUBS_SIZE, subsText);
            }
            else if(BOLD == true)
            {
                finalSubs = string.Format("<size={0}><b>{1}</b></size>", SUBS_SIZE, subsText);
            }
            else if(ITALIC == true)
            {
                finalSubs = string.Format("<size={0}><i>{1}</i></size>", SUBS_SIZE, subsText);
            }
            else
            {
                finalSubs = string.Format("<size={0}>{1}</size>", SUBS_SIZE, subsText);
            }

            var size = subsStyle.CalcSize(new GUIContent(finalSubs));
            var rect = new Rect(0, 0, size.x, size.y);
            rect.center = new Vector2(Screen.width / 2 + SUBS_OFFSET.x, Screen.height - (size.y / 2) - 12 + SUBS_OFFSET.y);
            GUI.color = new Color(0, 0, 0, Mathf.Lerp(0, 0.2f, subsColor.a));
            GUI.DrawTexture(rect, Texture2D.whiteTexture);

            rect.center -= new Vector2(2, -2);
            GUI.color = new Color(0, 0, 0, subsColor.a);
            GUI.Label(rect, finalSubs, subsStyle);
            rect.center += new Vector2(2, -2);

            GUI.color = subsColor;
            GUI.Label(rect, finalSubs, subsStyle);
            GUI.color = Color.white;

            // LY edit end //
        }

        //// LY edit begin ////

  //      void DoOverlayText(){
		//	overlayTextStyle.alignment = overlayTextAnchor;
		//	var rect = Rect.MinMaxRect(20, 10, Screen.width - 20, Screen.height - 10);
		//	overlayTextPos.y *= -1;
		//	rect.center += overlayTextPos;
		//	var finalText = string.Format("<size={0}><b>{1}</b></size>", overlayTextSize, overlayText);
		//	//shadow
		//	GUI.color = new Color(0,0,0,overlayTextColor.a);
		//	GUI.Label(rect, finalText, overlayTextStyle);
		//	rect.center += new Vector2(2, -2);
		//	//text
		//	GUI.color = overlayTextColor;
		//	GUI.Label(rect, finalText, overlayTextStyle);
		//	GUI.color = Color.white;
		//}

        void DoOverlayText()
        {
            if (overlayTextInfos == null || overlayTextInfos.Count <= 0)
                return;

            for (int a = 0; a < overlayTextInfos.Count; a++)
            {
                TextInfo tInfo = overlayTextInfos[a];
                if (tInfo == null)
                    continue;

                if (tInfo.overlayTextColor.a > 0 && !string.IsNullOrEmpty(tInfo.overlayText))
                {
                    overlayTextStyle.alignment = tInfo.overlayTextAnchor;
                    var rect = Rect.MinMaxRect(20, 10, Screen.width - 20, Screen.height - 10);
                    tInfo.overlayTextPos.y *= -1;
                    rect.center += tInfo.overlayTextPos;
                    var finalText = string.Format("<size={0}><b>{1}</b></size>", tInfo.overlayTextSize, tInfo.overlayText);
                    //shadow
                    GUI.color = new Color(0, 0, 0, tInfo.overlayTextColor.a);
                    GUI.Label(rect, finalText, overlayTextStyle);
                    rect.center += new Vector2(2, -2);
                    //text
                    GUI.color = tInfo.overlayTextColor;
                    GUI.Label(rect, finalText, overlayTextStyle);
                    GUI.color = Color.white;
                }
            }
        }

        //// LY edit end ////

        //// LY edit begin ////

        //void DoOverlayTexture(){
        //	var rect = new Rect(0, 0, overlayTexture.width * overlayTextureScale.x, overlayTexture.height * overlayTextureScale.y);
        //	rect.center = new Vector2( Screen.width/2, Screen.height/2 ) + overlayTexturePosition;
        //	GUI.color = overlayTextureColor;
        //	GUI.DrawTexture(rect, overlayTexture);
        //	GUI.color = Color.white;
        //}

        void DoOverlayTexture()
        {
            if (overlayTexInfos == null || overlayTexInfos.Count <= 0)
                return;

            for(int a = 0; a < overlayTexInfos.Count; a++)
            {
                TexInfo tInfo = overlayTexInfos[a];
                if (tInfo == null)
                    continue;

                if (tInfo.overlayTextureColor.a > 0 && tInfo.overlayTexture != null)
                {
                    GUI.depth = tInfo.depth;

                    var rect = new Rect(0, 0, tInfo.overlayTexture.width * tInfo.overlayTextureScale.x, tInfo.overlayTexture.height * tInfo.overlayTextureScale.y);
                    rect.center = new Vector2(Screen.width / 2, Screen.height / 2) + tInfo.overlayTexturePosition;
                    GUI.color = tInfo.overlayTextureColor;
                    GUI.DrawTexture(rect, tInfo.overlayTexture);
                    GUI.color = Color.white;
                }
            }
        }

        //// LY edit end ////

		void DoRuleOfThirds(){
			var lineWidth = 1;
			var y1 = new Rect(Screen.width/3, 0, lineWidth, Screen.height);
			var y2 = new Rect(y1.x * 2, 0, lineWidth, Screen.height);
			var x1 = new Rect(0, Screen.height/3, Screen.width, lineWidth);
			var x2 = new Rect(0, x1.y * 2, Screen.width, lineWidth);
			GUI.color = new Color(1,1,1,0.5f);
			GUI.DrawTexture(x1, Texture2D.whiteTexture);
			GUI.DrawTexture(x2, Texture2D.whiteTexture);
			GUI.DrawTexture(y1, Texture2D.whiteTexture);
			GUI.DrawTexture(y2, Texture2D.whiteTexture);
			GUI.color = Color.white;
		}

        //// LY add begin ////
        //// 闪烁提示文字 ////

        private static bool tipsOn = false;
        private static float timer = 0f;
        private static float reverse = 1f;

        private static GUIStyle tipStyle { get; set; }

        //private static string tipText = "再次点击跳过动画";
        private static int tipTextId = 621000;
        private static string tipText = "";
        private static Color tipColor = Color.white;
        private static float tipSize = 26;
        private static TextAnchor tipAnchor = TextAnchor.MiddleCenter;
        private static Vector2 tipPos = new Vector2(0f, 280f);

        /// <summary>
        /// 更新提示文字效果
        /// </summary>
        private void OnTipsUpdate()
        {
            if (tipsOn == false)
                return;

            timer += reverse * Time.deltaTime;
            if(timer >= 1)
            {
                timer = 1f;
                reverse *= -1;
            }
            else if(timer <= 0)
            {
                timer = 0f;
                reverse *= -1;
            }
            float alpha = timer;

            tipStyle.alignment = tipAnchor;
            var rect = Rect.MinMaxRect(20, 10, Screen.width - 20, Screen.height - 10);
            tipPos.y *= -1;
            rect.center += tipPos;
            var finalText = string.Format("<size={0}>{1}</size>", tipSize, tipText);
            //shadow
            GUI.color = new Color(0, 0, 0, alpha);
            GUI.Label(rect, finalText, tipStyle);
            rect.center += new Vector2(2, -2);
            //text
            tipColor.a = alpha;
            GUI.color = tipColor;
            GUI.Label(rect, finalText, tipStyle);
            GUI.color = Color.white;
        }

        public static void ShowTips()
        {
            EventMgr.Trigger("GetLocalString", tipTextId, current);

            timer = 0.5f;
            reverse = 1f;
            tipsOn = true;
        }

        public static void StopTips()
        {
            tipsOn = false;
        }

        public static void SetTipText(string text)
        {
            tipText = text;
        }

        //// LY add end ////
	}
}