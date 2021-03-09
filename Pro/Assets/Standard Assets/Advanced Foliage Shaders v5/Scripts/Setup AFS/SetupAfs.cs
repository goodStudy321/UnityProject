using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;
using UnityEngine.Rendering;


[ExecuteInEditMode]
[RequireComponent(typeof(WindZone))]
[AddComponentMenu("AFS/Setup Advanced Foliage Shader")]
public class SetupAfs : MonoBehaviour {
	//	Editor Variables
	#if UNITY_EDITOR
		public bool newEditor = true;
		public bool FoldLighting = false;
		public bool FoldFog = false;
		public bool FoldWind = false;
		public bool FoldRain = false;
		public bool FoldGrass = false;
		public bool FoldVegTerrain = false;
		public bool FoldSpecFade = false;
		public bool FoldBillboard = false;
		public bool FoldCulling = false;
		public bool FoldRender = false;
	#endif
	private Camera MainCam;
	
	// Lighting
	public bool isLinear;
    public bool AmbientLightingSH;

    // Wind
	public WindZone m_WindZone;
	private Vector3 WindDirection;
	private float WindStrength;
	private Vector3 WindPulseMagnitude;
	private float WindPulseFrenquency;
	private float WindTurbulence;

	//	Wind parameters which are needed by all shaders
	public Vector4 Wind = new Vector4(0.85f,0.075f,0.4f,0.5f);
	[Range(0.01f, 2.0f)]
	public float WindFrequency = 0.25f;
	// Wind on foliage
	[Range(0.1f, 10.0f)]
	public float Foliage_WindPrimaryStrength = 1.0f;
	[Range(0.1f, 10.0f)]
	public float Foliage_WindSecondaryStrength = 1.0f;
	[Range(0.0f, 10.0f)]
	public float Foliage_LeafTurbulence = 2.0f;
	[Range(0.1f, 25.0f)]
	public float Foliage_WaveSize = 2.0f;
	//	Wind parameters only needed by the advanced grass shaders
	[Range(0.01f, 4.0f)]
	public float Grass_WindStrength = 1.0f;
	[Range(0.00f, 10.0f)]
	public float Grass_WaveSize = 5.0f;
	[Range(0.0f, 1.0f)]
	public float Grass_WindSpeed = 0.3f;
		
	[Range(0.0f, 1.0f)]
	public float Grass_WindJitterVariation = 0.35f;
	[Range(0.0f, 1.0f)]
	public float Grass_WindJitterScale = 0.3f;
	//	Wind Parameters for Tree Creator Shaders
	[Range(0.0f, 10.0f)]
	public float Trees_WindPrimaryStrength = 1.0f;
	[Range(0.0f, 10.0f)]
	public float Trees_WindSecondaryStrength = 1.0f;
	
		private float temp_WindFrequency = 0.25f;
		private float temp_WindJitterFrequency = 0.25f;
		const float TwoPI = 2*Mathf.PI;
		private float freqSpeed = 0.05f;
		private float domainTime_Wind = 0.0f;
		private float domainTime_2ndBending = 0.0f;
		private float domainTime_Grass = 0.0f;

	private Vector3 GrassVelocity;
	//private float GrassSmoothTime = 4.0f;

	//	Rain Settings
	[Range(0.0f, 1.0f)]
	public float RainAmount = 0.0f;
	
	//	Terrain Detail Vegetation Settings
	public bool TerrainLegacyBending = true;
	public float DetailDistanceForGrassShader = 80.0f;
	public Color GrassWavingTint = Color.white;
	[Range(0.0f, 1.0f)]
	public float VertexLitTranslucency = 0.25f;
	[Range(0.0f, 1.0f)]
	public float VertexLitAlphaCutOff = 0.3f;
	public Color VertexLitSpecularReflectivity = new Color(0.2f,0.2f,0.2f,1f);
	[Range(1.0f, 1000.0f)]
	public float VertexLitVariationMultipilier = 333.3f;
	[Range(0.0f, 1.0f)]
	public float VertexLitLeafTurbulence = 0.5f;
	[Range(0.0f, 2.0f)]
	public float VertexLitBackfaceSmoothness = 1.0f;
	public Color VertexLitColorVariation = new Color(1f,1f,1f,0.0f);
	[Range(0.0f, 5.0f)]
	public float VertexLitHorizonFade = 0.0f;

	[Range(0.0f, 100.0f)]
	public Vector2 AfsSpecFade = new Vector2(80.0f, 20.0f);
	public Texture TerrainFoliageNrmSpecMap;
	[Range(0.0f, 1.0f)]
	public float GrassMinSmoothness = 0.2f;
	[Range(0.0f, 1.0f)]
	public float GrassMaxSmoothness = 0.6f;
	
	//	Terrain Sync settings
	public bool AutoSyncToTerrain = false;
	public Terrain SyncedTerrain;
	public bool AutoSyncInPlaymode = false;
	//	Tree Render settings
	[Range(0.0f, 1000.0f)]
	public float BillboardStart = 50.0f;
	[Range(0.0f, 30.0f)]
	public float BillboardFadeLenght = 5.0f;
	public Color AFSTreeColor = Color.black;
	[Range(10.0f, 100.0f)]
	public float BillboardFadeOutLength = 60.0f;
	public bool BillboardAdjustToCamera = true;
	[Range(10.0f, 90.0f)]
	public float BillboardAngleLimit = 30.0f;

	//	Camera Layer Culling Settings
	public bool EnableCameraLayerCulling = false;
	[Range(10, 300)]
	public int SmallDetailsDistance = 70;
	public LayerMask SmallDetailsLayer;
	[Range(10, 300)]
	public int MediumDetailsDistance = 90;
	public LayerMask MediumDetailsLayer;

	//	Special Render Settings
	public bool AllGrassObjectsCombined = false;

	// Init vars used by the scripts
	private Vector4 TempWind;

	private Quaternion WindRotation = Quaternion.identity;
	private float GrassWindSpeed;
	private float SinusWave;
	private Vector4 TriangleWaves;
	private float Oscillation;
	private Vector3 CameraForward = new Vector3(0.0f, 0.0f, 0.0f);
	//private Vector3 ShadowCameraForward = new Vector3(0.0f, 0.0f, 0.0f);
	private Vector3 CameraForwardVec;
	private float rollingX;
	private Vector3 lightDir;
	private Vector3 templightDir;
	private float CameraAngle;
	private Terrain[] allTerrains;
	
	private Vector3[] fLight = new Vector3[9];
	private Vector4[] vCoeff = new Vector4[3];

	// Shader properties
	private int ScaleID;
	//
	private int WindPID;
	private int AfsTreeWindMuliplierPID;
	private int AfsFoliageWindPID;
	private int AfsFoliageWindPulsMagnitudeFrequencyPID;
	private int AfsFoliageWindMultiplierPID;
	private int AfsFoliageTimeFrequencyPID;
	private int AfsFoliageWaveSizePID;
	private int AfsVertexLitTranslucencyPID;
	private int AfsVertexLitVariationPID;
	private int AfsVertexLitHorizonFadePID;

	private int AfsWindJitterVariationScalePID;
	private int AfsGrassWindPID;
	private int AfsWaveAndDistancePID;
	private int AfsWindRotationPID;
	//
	private int AfsRainamountPID;
	//
	private int AfsWavingTintPID;
	private int AfsTreeColorPID;
	private int AfsTerrainTreesPID;
	private int AfsBillboardCameraForwardPID;
	private int AfsBillboardBorderPID;
	//
	private int afs_SHAr;
	private int afs_SHAg;
	private int afs_SHAb;
	private int afs_SHBr;
	private int afs_SHBg;
	private int afs_SHBb;
	private int afs_SHC;


//	////////////////////////////////

	void Awake () {
		//
		afsSyncFrequencies();
		//
		afsCheckColorSpace();
		afsLightingSettings();
		afsUpdateWindfromZone();
		afsUpdateRain();
		afsSetupTerrainEngine();
		afsAutoSyncToTerrain();
		afsUpdateGrassTreesBillboards();
		afsSetupCameraLayerCulling();
		afsSetupGrassShader();

		InitPID();
	}

	public void Update () {
		afsLightingSettings();
		afsUpdateRain();
		afsUpdateGrassTreesBillboards();
		afsUpdateWindfromZone();
		#if UNITY_EDITOR
			afsAutoSyncToTerrain();
			afsCheckColorSpace();
			afsSetupTerrainEngine();
			afsSetupGrassShader();
		#endif
	}

	void InitPID() {
		WindPID = Shader.PropertyToID("_Wind");
		AfsTreeWindMuliplierPID = Shader.PropertyToID("_AfsTreeWindMuliplier");
		AfsFoliageWindPID = Shader.PropertyToID("_AfsFoliageWind");
		AfsFoliageWindPulsMagnitudeFrequencyPID = Shader.PropertyToID("_AfsFoliageWindPulsMagnitudeFrequency");
		AfsFoliageWindMultiplierPID = Shader.PropertyToID("_AfsFoliageWindMultiplier");
		AfsFoliageTimeFrequencyPID = Shader.PropertyToID("_AfsFoliageTimeFrequency");
		AfsFoliageWaveSizePID = Shader.PropertyToID("_AfsFoliageWaveSize");
		AfsVertexLitTranslucencyPID = Shader.PropertyToID("_AfsVertexLitTranslucency");
		AfsVertexLitVariationPID = Shader.PropertyToID("_AfsVertexLitVariation");
		AfsVertexLitHorizonFadePID = Shader.PropertyToID("_AfsVertexLitHorizonFade");
		AfsWindJitterVariationScalePID = Shader.PropertyToID("_AfsWindJitterVariationScale");
		AfsGrassWindPID = Shader.PropertyToID("_AfsGrassWind");
		AfsWaveAndDistancePID = Shader.PropertyToID("_AfsWaveAndDistance");
		AfsWindRotationPID = Shader.PropertyToID("_AfsWindRotation");
		//
		AfsRainamountPID = Shader.PropertyToID("_AfsRainamount");
		//
		AfsWavingTintPID = Shader.PropertyToID("_AfsWavingTint");
		AfsTreeColorPID = Shader.PropertyToID("_AfsTreeColor");
		AfsTerrainTreesPID = Shader.PropertyToID("_AfsTerrainTrees");
		AfsBillboardCameraForwardPID = Shader.PropertyToID("_AfsBillboardCameraForward");
		AfsBillboardBorderPID = Shader.PropertyToID("_AfsBillboardBorder");
		//
		afs_SHAr = Shader.PropertyToID("afs_SHAr");
		afs_SHAg = Shader.PropertyToID("afs_SHAg");
		afs_SHAb = Shader.PropertyToID("afs_SHAb");
		afs_SHBr = Shader.PropertyToID("afs_SHBr");
		afs_SHBg = Shader.PropertyToID("afs_SHBg");
		afs_SHBb = Shader.PropertyToID("afs_SHBb");
		afs_SHC = Shader.PropertyToID("afs_SHC");
	}


	public void Start() {
		WindRotation = this.transform.rotation;
	}


//	////////////////////////////////
//	Main Functions

	void afsSyncFrequencies() {
		temp_WindFrequency = WindFrequency;
		temp_WindJitterFrequency = Grass_WindSpeed;
		domainTime_Wind = 0.0f;
		domainTime_2ndBending = 0.0f;
		domainTime_Grass = 0.0f;
	}

	void afsCheckColorSpace() {
		#if UNITY_EDITOR
			// LINEAR
			if (PlayerSettings.colorSpace == ColorSpace.Linear) {
				if(!isLinear) {
					Debug.Log("Colorspace changed to linear.");
				}
				isLinear = true;
			}
			// GAMMA
			else {
				if(isLinear) {
					Debug.Log("Colorspace changed to gamma.");
				}
				isLinear = false;
			}
		#endif
	}

//	Lighting Settings
	void afsLightingSettings() {
		// Set ambient lighting for Tree Rendertex shaders
		UpdateLightingForClassicBillboards();
		// Set specular lighting for foliage shader
		Shader.SetGlobalVector("_AfsSpecFade", new Vector4(AfsSpecFade.x, AfsSpecFade.y, 1, 1 ));
	}

//	Special Render Settings
	void afsSetupGrassShader() {
		//	Tell the "advancedGrassShader" how to lit the objects
		if (Application.isPlaying || AllGrassObjectsCombined) {
			// Lighting based on baked normals
			Shader.DisableKeyword("IN_EDITMODE");
			Shader.EnableKeyword("IN_PLAYMODE");
		}
		else {
			// Lighting according to rotation
			Shader.DisableKeyword("IN_PLAYMODE");
			Shader.EnableKeyword("IN_EDITMODE");
		}
		Shader.SetGlobalVector("_AfsGrassSmoothness", new Vector2(GrassMinSmoothness, GrassMaxSmoothness));
	}

//	Terrain engine settings
	void afsSetupTerrainEngine() {

		if(TerrainLegacyBending) {
			Shader.EnableKeyword("_LEGACYBENDING");
		}
		else {
			Shader.DisableKeyword("_LEGACYBENDING");	
		}

		Shader.SetGlobalFloat("_AfsAlphaCutOff", VertexLitAlphaCutOff);
		if(isLinear){
			Shader.SetGlobalColor("_AfsSpecularReflectivity", VertexLitSpecularReflectivity.linear);	
		}
		else {
			Shader.SetGlobalColor("_AfsSpecularReflectivity", VertexLitSpecularReflectivity);	
		}
		if(TerrainFoliageNrmSpecMap != null) {
			Shader.SetGlobalTexture("_TerrianBumpTransSpecMap", TerrainFoliageNrmSpecMap);
		}
		else {
			Shader.SetGlobalTexture("_TerrianBumpTransSpecMap", null);	
		}
		Shader.SetGlobalFloat(AfsVertexLitTranslucencyPID, VertexLitTranslucency);
		Shader.SetGlobalFloat(AfsVertexLitHorizonFadePID, VertexLitHorizonFade);

		Shader.SetGlobalFloat("_VertexLitLeafTurbulence", VertexLitLeafTurbulence);
		Shader.SetGlobalFloat("_VertexLitBackfaceSmoothness", VertexLitBackfaceSmoothness);
		Shader.SetGlobalColor("_VertexLitColorVariation", VertexLitColorVariation.linear);
	}


	void afsUpdateWindfromZone() {
		WindDirection = this.transform.forward;
		TempWind.x = WindDirection.x;
		TempWind.y = WindDirection.y;
		TempWind.z = WindDirection.z;
		if(m_WindZone == null) {
			m_WindZone = GetComponent<WindZone>();
		}
		WindStrength = m_WindZone.windMain;
		TempWind.w = WindStrength;

		//WindPulseMagnitude = WindStrength * m_WindZone.windPulseMagnitude; // must be direction
		float WindstrengthMagnitude = 0.0f;
		if (m_WindZone.windPulseFrequency != 0.0f) {
			WindstrengthMagnitude = m_WindZone.windPulseMagnitude * (1.0f + Mathf.Sin(Time.time * m_WindZone.windPulseFrequency) + 1.0f + Mathf.Sin(Time.time * m_WindZone.windPulseFrequency * 3.0f) ) * 0.5f;
			WindPulseMagnitude = new Vector3(WindDirection.x * WindStrength * WindstrengthMagnitude, WindDirection.y * WindStrength * WindstrengthMagnitude, WindDirection.z * WindStrength * WindstrengthMagnitude); //WindStrength * m_WindZone.windPulseMagnitude;
		}
		else {
			WindPulseMagnitude = new Vector3(0,0,0);
		}

		WindPulseFrenquency = m_WindZone.windPulseFrequency * 2.0f; // * Mathf.Sin(Time.realtimeSinceStartup) * 0.5f; //); // * ( Mathf.Sin(Time.deltaTime * 0.756f) * 2.0f - 1.0f) );
		WindTurbulence = m_WindZone.windTurbulence /* * m_WindZone.windMain */; // to match trees
		WindDirection = new Vector3(WindDirection.x * WindStrength, WindDirection.y * WindStrength, WindDirection.z * WindStrength);

	//	Trees
		Shader.SetGlobalVector(WindPID, new Vector4(WindDirection.x, WindDirection.y, WindDirection.z, Mathf.Max(0.1f, WindTurbulence)) );
		Shader.SetGlobalVector(AfsTreeWindMuliplierPID, new Vector4(Trees_WindPrimaryStrength, Trees_WindSecondaryStrength, 0.0f, 0.0f));
	
	//	Foliage
		//Shader.SetGlobalVector("_AfsFoliageWind", new Vector4(WindDirection.x + WindPulseMagnitude.x, WindDirection.y + WindPulseMagnitude.y, WindDirection.z + WindPulseMagnitude.z, Mathf.Max(0.1f, WindTurbulence)) );
		Shader.SetGlobalVector(AfsFoliageWindPID, new Vector4(WindDirection.x, WindDirection.y, WindDirection.z, Mathf.Max(0.0f, WindTurbulence)) );
		Shader.SetGlobalVector(AfsFoliageWindPulsMagnitudeFrequencyPID, new Vector4(WindPulseMagnitude.x, WindPulseMagnitude.y, WindPulseMagnitude.z, WindPulseFrenquency) );
		Shader.SetGlobalVector(AfsFoliageWindMultiplierPID, new Vector4(Foliage_WindPrimaryStrength, Foliage_WindSecondaryStrength, 0.0f, 0.0f ));

	//	Calculate LeafTurbulence
		domainTime_Wind = (domainTime_Wind + temp_WindFrequency * Time.deltaTime * 2.0f); // % TwoPI; / % TwoPI causes hiccups
		domainTime_2ndBending = domainTime_2ndBending + Time.deltaTime;
		// x: time * frequency, y: time, zw: turbulence for 2nd bending
		Shader.SetGlobalVector(AfsFoliageTimeFrequencyPID, new Vector4(domainTime_Wind, domainTime_2ndBending, 0.375f * (1.0f + Foliage_LeafTurbulence), 0.193f * (1.0f + Foliage_LeafTurbulence)));
		temp_WindFrequency = Mathf.MoveTowards(temp_WindFrequency, m_WindZone.windTurbulence, freqSpeed);
		Shader.SetGlobalFloat(AfsFoliageWaveSizePID, (0.5f / Foliage_WaveSize) );
	
	//	VertexLit
		Shader.SetGlobalFloat(AfsVertexLitVariationPID, VertexLitVariationMultipilier);

	// Grass
		// We must not use Unity.Time.time and Grass_WindSpeed directly, so:
		domainTime_Grass = (domainTime_Grass + temp_WindJitterFrequency * Time.deltaTime); // % TwoPI; / % TwoPI causes hiccups
		GrassWindSpeed = domainTime_Grass * 0.1f;
	// As Turbulence only alreday bends foliage and trees we add it to Grass_WindSpeed * WindStrength too
		temp_WindJitterFrequency = Mathf.MoveTowards(temp_WindJitterFrequency, Grass_WindSpeed * WindStrength + WindTurbulence * 0.5f, freqSpeed);
		//Shader.SetGlobalVector("_AfsWaveAndDistance", new Vector4( GrassWindSpeed * (WindStrength + WindTurbulence) * Grass_WindStrength, Grass_WaveSize, WindStrength * 0.1f , DetailDistanceForGrassShader * DetailDistanceForGrassShader ) );
		//Shader.SetGlobalVector("_AfsWaveAndDistance", new Vector4( GrassWindSpeed, Grass_WaveSize, WindStrength * 0.1f , DetailDistanceForGrassShader * DetailDistanceForGrassShader ) );
		Shader.SetGlobalVector(AfsWindJitterVariationScalePID, new Vector4(Grass_WindJitterVariation, Grass_WindJitterScale, 0.0f, 0.0f) ); // 4.0f
		//TempWind.w += WindTurbulence;
		Shader.SetGlobalVector(AfsGrassWindPID, TempWind);
		Shader.SetGlobalVector(AfsWaveAndDistancePID, new Vector4( GrassWindSpeed, Grass_WaveSize, (WindStrength + WindstrengthMagnitude * WindStrength + WindTurbulence) * Grass_WindStrength , DetailDistanceForGrassShader * DetailDistanceForGrassShader ) );

		Quaternion rotation = this.transform.rotation;
		WindRotation = Quaternion.Slerp(WindRotation, rotation, 0.1f * Time.deltaTime);
		Matrix4x4 WindRotMatrix = new Matrix4x4();
		WindRotMatrix.SetTRS( Vector3.zero, WindRotation, Vector3.one );
		Shader.SetGlobalMatrix(AfsWindRotationPID, WindRotMatrix);

	}


//	Update Wind Settings / Simple wind animation for the foliage and grass shaders
	void afsUpdateWind() {
	//	Sync Wind Dir to rotation
	//	if (SyncWindDir) {
			Wind = new Vector4(transform.forward.x, transform.forward.y, transform.forward.z, Wind.w);
	//	}
	//	Set Main Wind
		TempWind = Wind;
		TempWind.w *= 2.0f;
		Shader.SetGlobalVector(WindPID, TempWind);
		// Currently not used in the shaders, see below
//		Shader.SetGlobalFloat("_WindFrequency", WindFrequency);
		// We must not use Unity.Time.time and WindFrequency/Grass_WindSpeed directly, so:
		// http://answers.unity3d.com/questions/274098/how-to-smooth-between-values.html
		domainTime_Wind = (domainTime_Wind + temp_WindFrequency * Time.deltaTime * 2.0f); // % TwoPI; / % TwoPI causes hiccups
		domainTime_2ndBending = domainTime_2ndBending + Time.deltaTime;
		// x: time * frequency, y: time, zw: turbulence for 2nd bending
		Shader.SetGlobalVector("_AfsTimeFrequency", new Vector4(domainTime_Wind, domainTime_2ndBending, 0.375f * (1.0f + temp_WindFrequency * Foliage_LeafTurbulence), 0.193f * (1.0f + temp_WindFrequency * Foliage_LeafTurbulence)));
		//Shader.SetGlobalFloat("_AfsTurbulence", 0.375f * (1.0f + temp_WindFrequency * Foliage_LeafTurbulence));
		temp_WindFrequency = Mathf.MoveTowards(temp_WindFrequency, WindFrequency, freqSpeed);

		Shader.SetGlobalFloat("_AfsWaveSize", (0.5f / Foliage_WaveSize) );
		//Shader.SetGlobalVector("_AFSWindMuliplier", WindMuliplierForTreeShader);

		Shader.SetGlobalFloat("_AfsWindJitterScale", Grass_WindJitterScale * 10.0f); // 4.0f	
		Shader.SetGlobalVector("_AfsGrassWind", TempWind * Grass_WindStrength);
		// We must not use Unity.Time.time and Grass_WindSpeed directly, so:
		domainTime_Grass = (domainTime_Grass + temp_WindJitterFrequency * Time.deltaTime); // % TwoPI; / % TwoPI causes hiccups
		GrassWindSpeed = domainTime_Grass * 0.1f;
		temp_WindJitterFrequency = Mathf.MoveTowards(temp_WindJitterFrequency, Grass_WindSpeed, freqSpeed);
		
		// _AfsWaveAndDistance = Wind speed, wave size, wind amount, max pow2 distance
		Shader.SetGlobalVector("_AfsWaveAndDistance", new Vector4( GrassWindSpeed, Grass_WaveSize, TempWind.w, DetailDistanceForGrassShader * DetailDistanceForGrassShader ) );
	}

//	Update Rain Settings
	void afsUpdateRain() {
		Shader.SetGlobalFloat(AfsRainamountPID, RainAmount);
	}

//	AutoSyncToTerrain
	void afsAutoSyncToTerrain() {
		if(AutoSyncToTerrain && SyncedTerrain != null) {
			DetailDistanceForGrassShader = SyncedTerrain.detailObjectDistance;
			BillboardStart = SyncedTerrain.treeBillboardDistance;
			BillboardFadeLenght = SyncedTerrain.treeCrossFadeLength;
			GrassWavingTint = SyncedTerrain.terrainData.wavingGrassTint;
		}
	}
	
//	Grass, Tree and Billboard Settings
	void afsUpdateGrassTreesBillboards() {
		// DetailDistanceForGrassShader has already been passed with: _AfsWaveAndDistance
		Shader.SetGlobalColor(AfsWavingTintPID, GrassWavingTint); 
		// Tree Variables
		Shader.SetGlobalColor(AfsTreeColorPID, AFSTreeColor);
		// Billboardstart
		// We were too late: 
		// Shader.SetGlobalVector("_AfsTerrainTrees", new Vector4(BillboardStart, BillboardFadeLenght, BillboardFadeOutLength, 0 ));
		Shader.SetGlobalVector(AfsTerrainTreesPID, new Vector4(BillboardStart + BillboardFadeLenght, BillboardFadeLenght, BillboardFadeOutLength, 0 ));
		//	Camera Settings for the Billboard Shader
		if (BillboardAdjustToCamera) {
			if (Camera.main) {
				MainCam = Camera.main;
				CameraForward = MainCam.transform.forward;
				//ShadowCameraForward = CameraForward;
				rollingX = MainCam.transform.eulerAngles.x;
				if (rollingX >= 270.0f) {					// looking up
					rollingX = (rollingX - 270.0f);
					rollingX = (90.0f - rollingX);
				}
				else {										// looking down
					if (rollingX > BillboardAngleLimit) {
						rollingX = Mathf.Lerp(rollingX, 0.0f,  (rollingX / BillboardAngleLimit) - 1.0f );
					}
					rollingX *= -1;
				}
			}
			#if UNITY_EDITOR
				else {
					if (!Application.isPlaying) {
						Debug.Log("You have to tag your Camera as MainCamera");
					}
				}
			#endif
		}
		else {
			rollingX = 0.0f;
		}
		CameraForward *= rollingX / 90.0f;
		Shader.SetGlobalVector(AfsBillboardCameraForwardPID, new Vector4( CameraForward.x, CameraForward.y, CameraForward.z, 1.0f));
	}

//	Camera Layer Culling Settings
	int GetLayerNumber(int LayerValue) {
		int layerNumber = 0;
		int layer = LayerValue;
		while(layer > 0)
		{
		    layer = layer >> 1;
		    layerNumber++;
		}
		return (layerNumber - 1);
	}
	public void afsSetupCameraLayerCulling() {
		if(EnableCameraLayerCulling) { 
			// Get layer numbers
			int smallLayerNumber = GetLayerNumber(SmallDetailsLayer.value);
			int mediumLayerNumber = GetLayerNumber(MediumDetailsLayer.value);

			for (int i = 0; i < Camera.allCameras.Length; i++) {
				float[] distances = new float[32];
				distances = Camera.allCameras[i].layerCullDistances;
				if (smallLayerNumber > 0)
					distances[smallLayerNumber] = SmallDetailsDistance;			// small things like DetailDistance of the terrain engine
				if (mediumLayerNumber > 0)
					distances[mediumLayerNumber] = MediumDetailsDistance;		// small things like DetailDistance of the terrain engine
				Camera.allCameras[i].layerCullDistances = distances;
				distances = null;
			}
		}
	}
	public void afsResetCameraLayerCulling() {
		// Get layer numbers
		int smallLayerNumber = GetLayerNumber(SmallDetailsLayer.value);
		int mediumLayerNumber = GetLayerNumber(MediumDetailsLayer.value);
		
		for (int i = 0; i < Camera.allCameras.Length; i++) {
			float[] distances = new float[32];
			distances = Camera.allCameras[i].layerCullDistances;
			if (smallLayerNumber > 0)
				distances[smallLayerNumber] = Camera.allCameras[i].farClipPlane;		// small things like DetailDistance of the terrain engine
			if (mediumLayerNumber > 0)
				distances[mediumLayerNumber] = Camera.allCameras[i].farClipPlane;		// small things like DetailDistance of the terrain engine
			Camera.allCameras[i].layerCullDistances = distances;
			distances = null;
		}
	}

//	////////////////////////////////
//	Helper functions

	//	Update Light Settings for Tree Creator Rendertex Shaders
	private void UpdateLightingForClassicBillboards() {
		// Skybox
        if (RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.Skybox) {
            AmbientLightingSH = true;
            // Udpate SH Lighting
			UdpateSHLightingforBillboards();
            Shader.EnableKeyword("AFS_SH_AMBIENT");
            Shader.DisableKeyword("AFS_COLOR_AMBIENT");
            Shader.DisableKeyword("AFS_GRADIENT_AMBIENT");
        }
        // Trilight
        else if (RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.Trilight) {
        	AmbientLightingSH = false;
        	
	        Shader.SetGlobalColor("_AfsSkyColor", RenderSettings.ambientSkyColor.linear); 
			Shader.SetGlobalColor("_AfsGroundColor", RenderSettings.ambientGroundColor.linear); 
			Shader.SetGlobalColor("_AfsEquatorColor", RenderSettings.ambientEquatorColor.linear);
			
			Shader.DisableKeyword("AFS_SH_AMBIENT");
            Shader.DisableKeyword("AFS_COLOR_AMBIENT");
            Shader.EnableKeyword("AFS_GRADIENT_AMBIENT");

        //	Set factor for billboard border correction
            Color HSV = RenderSettings.ambientLight;
            float hue, S, V;
            Color.RGBToHSV(HSV, out hue, out S, out V);
            Shader.SetGlobalFloat(AfsBillboardBorderPID, Mathf.Pow(V, 0.25f) );
        }
        // Flat
        else if (RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.Flat) {
            AmbientLightingSH = false;
            Shader.SetGlobalVector("_AfsAmbientColor", RenderSettings.ambientLight); 
            Shader.DisableKeyword("AFS_SH_AMBIENT");
            Shader.EnableKeyword("AFS_COLOR_AMBIENT");
            Shader.DisableKeyword("AFS_GRADIENT_AMBIENT");

        //	Set factor for billboard border correction
            Color HSV = RenderSettings.ambientSkyColor.linear;
            float hue, S, V;
            Color.RGBToHSV(HSV, out hue, out S, out V);
            Shader.SetGlobalFloat(AfsBillboardBorderPID, Mathf.Pow(V, 0.25f) );
        }
	}

	private void UdpateSHLightingforBillboards() {
		// http://www.ppsloan.org/publications/StupidSH36.pdf

		SphericalHarmonicsL2 probe = RenderSettings.ambientProbe;

		fLight[0].x = probe[0,0];
		fLight[0].y = probe[1,0];
		fLight[0].z = probe[2,0];

		fLight[1].x = probe[0,1];
		fLight[1].y = probe[1,1];
		fLight[1].z = probe[2,1];

		fLight[2].x = probe[0,2];
		fLight[2].y = probe[1,2];
		fLight[2].z = probe[2,2];

		fLight[3].x = probe[0,3];
		fLight[3].y = probe[1,3];
		fLight[3].z = probe[2,3];

		fLight[4].x = probe[0,4];
		fLight[4].y = probe[1,4];
		fLight[4].z = probe[2,4];

		fLight[5].x = probe[0,5];
		fLight[5].y = probe[1,5];
		fLight[5].z = probe[2,5];

		fLight[6].x = probe[0,6];
		fLight[6].y = probe[1,6];
		fLight[6].z = probe[2,6];

		fLight[7].x = probe[0,7];
		fLight[7].y = probe[1,7];
		fLight[7].z = probe[2,7];

		fLight[8].x = probe[0,8];
		fLight[8].y = probe[1,8];
		fLight[8].z = probe[2,8];

		float s_fSqrtPI = 3.54490770181F;
		float fC0 = 1.0f/(2.0f*s_fSqrtPI);
		float fC1 = (float)Mathf.Sqrt(3.0f)/(3.0f*s_fSqrtPI);
		float fC2 = (float)Mathf.Sqrt(15.0f)/(8.0f*s_fSqrtPI);
		float fC3 = (float)Mathf.Sqrt(5.0f)/(16.0f*s_fSqrtPI);
		float fC4 = 0.5f*fC2;

		float ambientIntensity = RenderSettings.ambientIntensity;
		if (isLinear) {
			ambientIntensity = Mathf.Pow(ambientIntensity * (1.0f / ambientIntensity), 1.0f/2.2f);
		}
		else {
			ambientIntensity = ambientIntensity * (1.0f / ambientIntensity);
		}

		int iC;
		for( iC=0; iC<3; iC++ )
		{
			vCoeff[iC].x = -fC1 * fLight[3][iC];
			vCoeff[iC].y = -fC1 * fLight[1][iC];
			vCoeff[iC].z = fC1 * fLight[2][iC];
			vCoeff[iC].w = fC0 * fLight[0][iC] - fC3*fLight[6][iC];
		}
		Shader.SetGlobalVector(afs_SHAr, vCoeff[0]*ambientIntensity);
		Shader.SetGlobalVector(afs_SHAg, vCoeff[1]*ambientIntensity);
		Shader.SetGlobalVector(afs_SHAb, vCoeff[2]*ambientIntensity);

		for( iC=0; iC<3; iC++ )
		{
		    vCoeff[iC].x =      fC2*fLight[4][iC];
		    vCoeff[iC].y =     -fC2*fLight[5][iC];
		    vCoeff[iC].z = 3.0f*fC3*fLight[6][iC];
		    vCoeff[iC].w =     -fC2*fLight[7][iC];
		}
		Shader.SetGlobalVector(afs_SHBr, vCoeff[0]*ambientIntensity);
		Shader.SetGlobalVector(afs_SHBg, vCoeff[1]*ambientIntensity);
		Shader.SetGlobalVector(afs_SHBb, vCoeff[2]*ambientIntensity);

		vCoeff[0].x = fC4*fLight[8][0];
		vCoeff[0].y = fC4*fLight[8][1];
		vCoeff[0].z = fC4*fLight[8][2];
		vCoeff[0].w = 1.0f;
		Shader.SetGlobalVector(afs_SHC, vCoeff[0]*ambientIntensity);

	//	Set factor for billboard border correction by somehow approximating the average brightness...
	//	Works only for gradients...
	//	Shader.SetGlobalFloat(AfsBillboardBorderPID, Mathf.Clamp01( (vCoeff[0].x + vCoeff[0].y + vCoeff[0].z) * ambientIntensity * 1.0f));

	}

	/*private Color Desaturate(float r, float g, float b) {
		float grey = 0.3f * r + 0.59f * g + 0.11f * b;
		r = grey * BillboardAmbientLightDesaturationFactor + r * (1.0f - BillboardAmbientLightDesaturationFactor);
		g = grey * BillboardAmbientLightDesaturationFactor + g * (1.0f - BillboardAmbientLightDesaturationFactor);
		b = grey * BillboardAmbientLightDesaturationFactor + b * (1.0f - BillboardAmbientLightDesaturationFactor);
		return (new Color(r, g, b, 1.0f));
	}*/
	float CubicSmooth( float x ) {   
		return x * x *( 3.0f - 2.0f * x );
	}
	float TriangleWave( float x ) {   
		//	return abs( frac( x + 0.5f ) * 2.0f - 1.0f ); 
		return Mathf.Abs( ( x + 0.5f ) % 1.0f * 2.0f - 1.0f );
	}
	float SmoothTriangleWave( float x ) {   
		return CubicSmooth( TriangleWave( x ) );
	}

	Vector4 CubicSmooth( Vector4 x ) {   
		//	return x * x *( 3.0 - 2.0 * x );
		x = Vector4.Scale(x,x);
		x = Vector4.Scale(x, new Vector4 (3.0f,3.0f,3.0f,3.0f) - 2.0f * x);
		return x ;
	}
	Vector4 TriangleWave( Vector4 x ) {   
		//	return abs( frac( x + 0.5f ) * 2.0f - 1.0f );
			// no frac as the input uses sin
			x = (x + new Vector4(0.5f,0.5f,0.5f,0.5f)) * 2.0f - new Vector4(1.0f,1.0f,1.0f,1.0f);
		return AbsVecFour(x);
	}
	Vector4 SmoothTriangleWave( Vector4 x ) {   
		return CubicSmooth( TriangleWave( x ) );
	}

	Vector4 FracVecFour (Vector4 a) {
		a.x = a.x % 1.0f; 
		a.y = a.y % 1.0f; 
		a.z = a.z % 1.0f; 
		a.w = a.w % 1.0f;
		return a;
	}
	Vector4 AbsVecFour (Vector4 a) {
		a.x = Mathf.Abs(a.x); 
		a.y = Mathf.Abs(a.y);
		a.z = Mathf.Abs(a.z);
		a.w = Mathf.Abs(a.w); 
		return a;
	}
}