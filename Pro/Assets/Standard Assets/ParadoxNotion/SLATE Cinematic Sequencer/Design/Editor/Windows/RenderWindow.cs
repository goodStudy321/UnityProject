#if UNITY_EDITOR && !NO_UTJ

using UnityEditor;
using UnityEngine;
using System.Collections;
using RenderFormat = Slate.Prefs.RenderSettings.RenderFormat;

namespace Slate{

	public class RenderWindow : EditorWindow {

		private Prefs.RenderSettings settings;
		private ImageSequenceRecorder recorder;
		// private MovieRecorder recorder2;
		private FixDeltaTime deltaTimeFixer;
		private bool isRendering;

		private Cutscene cutscene{
			get {return CutsceneEditor.current != null? CutsceneEditor.current.cutscene : null;}
		}

		public static void Open(){
			var window = CreateInstance<RenderWindow>();
			window.ShowUtility();
		}

		void OnEnable(){
			titleContent = new GUIContent("Slate Render Utility");
			settings = Prefs.renderSettings;
			minSize = new Vector2(410, 250);
		}

		void OnDisable(){
			Prefs.renderSettings = settings;
			Done();
		}

		void Update(){

			if (!isRendering || cutscene == null){
				return;
			}

			cutscene.currentTime += 1f/settings.framerate;
			if (cutscene.currentTime >= cutscene.cameraTrack.endTime){
				Done();
			}
		}

		void OnGUI(){

			if (isRendering){
				Repaint();
			}

			settings.renderFormat = (RenderFormat)EditorGUILayout.EnumPopup("Render Format", settings.renderFormat);
			GUILayout.BeginHorizontal();
			settings.folderName = EditorGUILayout.TextField("SubFolder In Project", settings.folderName);
			if (GUILayout.Button("F", GUILayout.Width(20), GUILayout.Height(14))){
				OpenTargetFolder();
			}
			GUILayout.EndHorizontal();
			settings.fileName   = EditorGUILayout.TextField("Filename", settings.fileName);

			GUILayout.BeginVertical("box");

			if (settings.renderFormat == RenderFormat.PNGImageSequence || settings.renderFormat == RenderFormat.EXRImageSequence){
				settings.splitRenderBuffer = EditorGUILayout.Toggle("Render Passes", settings.splitRenderBuffer);
			} else {
				settings.resolutionWidth = Mathf.Clamp( EditorGUILayout.IntField("Resolution Width", settings.resolutionWidth), 64, 1920 );
			}

			settings.framerate = Mathf.Clamp( EditorGUILayout.IntField("Frame Rate", settings.framerate), 2, 60);
			EditorGUILayout.LabelField("Resolution", EditorTools.GetGameViewSize().ToString("0"));
			EditorGUILayout.HelpBox("Rendering Resolution is taken from the Game Window.\nYou can create custom resolutions with the '+' button through the second dropdown in the Game window toolbar (where it usually reads 'Free Aspect').", MessageType.None);

			GUILayout.EndVertical();

			if (cutscene == null){
				EditorGUILayout.HelpBox("Cutscene is null or the Cutscene Editor is not open", MessageType.Error);
			}

			if (cutscene.cameraTrack == null){
				EditorGUILayout.HelpBox("Cutscene has no Camera Track", MessageType.Warning);
			}

			GUI.enabled = cutscene != null && cutscene.cameraTrack != null && !isRendering;
			if (GUILayout.Button(isRendering? "RENDERING..." : "RENDER", GUILayout.Height(50))){
				Begin();
			}

			GUI.enabled = true;
			if (isRendering && GUILayout.Button("CANCEL")){
				Done();
			}
		}


		void Begin(){

			if (isRendering){
				return;
			}

			cutscene.Rewind();

			EditorApplication.ExecuteMenuItem ("Window/Game");
			isRendering = true;
			cutscene.currentTime = cutscene.cameraTrack.startTime;
			cutscene.Sample();

			CutsceneEditor.OnStopInEditor += Done;


			if (settings.renderFormat == RenderFormat.PNGImageSequence || settings.renderFormat == RenderFormat.EXRImageSequence){

				if (Application.isPlaying){
					deltaTimeFixer = DirectorCamera.current.cam.GetAddComponent<FixDeltaTime>();
					deltaTimeFixer.targetFramerate = settings.framerate;
				}

				if (settings.renderFormat == RenderFormat.PNGImageSequence){
					recorder = DirectorCamera.current.cam.GetAddComponent<PngRecorder>();
				}

				if (settings.renderFormat == RenderFormat.EXRImageSequence){
					recorder = DirectorCamera.current.cam.GetAddComponent<ExrRecorder>();
				}

				recorder.dirName = "./" + settings.folderName;
				recorder.fileName = settings.fileName;
				recorder.captureGBuffer = settings.splitRenderBuffer;
				recorder.captureFramebuffer = true;
				recorder.Initialize();
			}


/*
			if (settings.renderFormat == RenderFormat.MP4Video || settings.renderFormat == RenderFormat.GIFAnimation){

				if (settings.renderFormat == RenderFormat.MP4Video){
					recorder2 = DirectorCamera.current.cam.GetAddComponent<MP4Recorder>();
				}

				if (settings.renderFormat == RenderFormat.GIFAnimation){
					recorder2 = DirectorCamera.current.cam.GetAddComponent<GifRecorder>();
				}

				recorder2.dirName = "./" + settings.folderName;
				recorder2.fileName = settings.fileName;
				recorder2.resolutionWidth = settings.resolutionWidth;
				recorder2.framerate = settings.framerate;
				recorder2.BeginRecording();
			}
*/
		}

		void Done(){

			if (!isRendering){
				return;
			}

			CutsceneEditor.OnStopInEditor -= Done;
			isRendering = false;

			if (recorder != null){
				DestroyImmediate(recorder, true);
			}
/*
			if (recorder2 != null){
				recorder2.Flush();
				recorder2.EndRecording();
				DestroyImmediate(recorder2, true);
			}
*/
			if (deltaTimeFixer != null){
				DestroyImmediate(deltaTimeFixer, true);
			}

			cutscene.Rewind();
			OpenTargetFolder();
		}

		void OpenTargetFolder(){
			var path = Application.dataPath.Replace("/Assets", "/" + settings.folderName + "/");
			System.IO.Directory.CreateDirectory(path); //ensure folder exists
			Application.OpenURL(path);
		}
	}
}

#endif