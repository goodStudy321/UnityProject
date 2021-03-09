using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
using System.Text;

namespace FastOcean
{
    public class UI : MonoBehaviour
    {
        public Text info = null;
        public Toggle autoNextToggle = null;
        public Toggle autoSailToggle = null;
        public Toggle gammaToggle = null;

        public ToggleGroup qualityGroup = null;

        public Slider gridSize = null;

        public float nextTime = 12;
        public bool autoNext = true;
        public bool autoSail = false;

        public GameObject sail = null;
        public GameObject fps = null;

        public GameObject stick = null;

        public FScaleScreen screenScale = null;
        public Slider screenScaleSlider = null;
        
        public Toggle antialiasingToggle = null;
        public bool isAntialiasing = true;

        public List<Color> baseColorKeys = new List<Color>();
        public List<Color> deepColorKeys = new List<Color>();

        public Slider baseColorSlider = null;
        public Slider deepColorSlider = null;

        public Text baseColorText = null;
        public Text deepColorText = null;

        private float timeTotal = 0.0f;

        void Start()
        {
            if (autoNextToggle != null)
                autoNextToggle.isOn = autoNext;

            if (autoSailToggle != null)
                autoSailToggle.isOn = autoSail;

            if (antialiasingToggle != null)
                antialiasingToggle.isOn = isAntialiasing;
        }

        // static int countLoop = 0;
        // Update is called once per frame
        public void OnClickNextScene() 
        {
             Scene scene = SceneManager.GetActiveScene();
             int i = scene.buildIndex;
             SceneManager.LoadScene((i + 1) % SceneManager.sceneCountInBuildSettings, LoadSceneMode.Single);
        }

        void FixedUpdate()
        {
            if (FOcean.instance == null)
                return;

            if (autoNext)
            {
                timeTotal += Time.fixedDeltaTime;
                if (timeTotal > nextTime)
                {
                    OnClickNextScene();
                }
            }
            else
                timeTotal = 0.0f;

            if(sail != null && fps != null && stick != null)
            {
                bool bSail = sail.activeSelf;
                sail.SetActive(autoSail);
                fps.SetActive(!autoSail);
                stick.SetActive(!autoSail);

                if(bSail != sail.activeSelf)
                {
                    TurnQuality();
                }

                FOcean.instance.envParam.trailer = autoSail ? sail.transform : null;
            }

            if (Camera.main != null)
            {
                FColorCorrection gammaCorrection = (FColorCorrection)Camera.main.gameObject.GetComponent(typeof(FColorCorrection));
                if (gammaCorrection != null && gammaToggle != null)
                {
                    gammaCorrection.enabled = gammaToggle.isOn;
                }
            }

            if(screenScale != null && screenScaleSlider != null)
               screenScaleSlider.value = screenScale.scale;

            QualitySettings.anisotropicFiltering = AnisotropicFiltering.Enable;

            if (Camera.main != null)
            {
                FAntialiasing antialiasing = (FAntialiasing)Camera.main.gameObject.GetComponent(typeof(FAntialiasing));
                if (antialiasing != null && antialiasingToggle != null)
                {
                    antialiasing.enabled = isAntialiasing;
                }
            }

            if (gridSize != null && FOcean.instance.mainFG != null)
            {
                gridSize.enabled = FOcean.instance.supportSM3;
                gridSize.value = FOcean.instance.mainFG.baseParam.usedGridSize;
            }
            
            FOcean.instance.envParam.underColor = FOcean.instance.GetBaseColor();

            if(baseColorSlider != null && baseColorText != null)
            {
                Color s = FOcean.SuppleColor(FOcean.instance.GetBaseColor());

                ColorBlock block = baseColorSlider.colors;
                block.highlightedColor = s;
                block.normalColor = s;
                baseColorSlider.colors = block;

                baseColorText.color = s;
            }

            if (deepColorSlider != null && deepColorText != null)
            {
                Color s = FOcean.SuppleColor(FOcean.instance.GetDeepColor());

                ColorBlock block = deepColorSlider.colors;
                block.highlightedColor = s;
                block.normalColor = s;
                deepColorSlider.colors = block;

                deepColorText.color = s;
            }
            
            FOcean.instance.UnderStateReset();
        }

        public void TurnNext()
        {
            autoNext = autoNextToggle.isOn;
        }

        public void TurnSail()
        {
            autoSail = autoSailToggle.isOn;
        }

        public void ChangeGridSize()
        {
            if (FOcean.instance == null)
                return;

            if (gridSize == null)
                return;

            if (FOcean.instance.mainFG != null)
            {
                FOcean.instance.mainFG.baseParam.usedGridSize = (int)gridSize.value;
            }
        }

        public void ChangeScreenScale()
        {
            if (screenScale == null || screenScaleSlider == null)
                return;

            screenScale.scale  = (int)screenScaleSlider.value;
        }

        public void ChangeBaseColor()
        {
            if (FOcean.instance == null || baseColorSlider == null)
                return;

            int i = (int)baseColorSlider.value;
            if (i < baseColorKeys.Count)
            {
                FOcean.instance.SetBaseColor(baseColorKeys[i]);
            }
        }

        public void ChangeDeepColor()
        {
            if (FOcean.instance == null || deepColorSlider == null)
                return;

            int i = (int)deepColorSlider.value;
            if (i < deepColorKeys.Count)
            {
                FOcean.instance.SetDeepColor(deepColorKeys[i]);
            }
        }

        public void ChangeAntialiasing()
        {
            isAntialiasing = antialiasingToggle.isOn;
        }

        public void TurnQuality()
        {
            if (FOcean.instance == null)
                return;

            if (qualityGroup == null)
                return;

            if (Camera.main == null)
                return;

            FSunShafts sunshaft = Camera.main.GetComponent<FSunShafts>();
            FClouds clouds = Camera.main.GetComponent<FClouds>();
            FGlareEffect glare = Camera.main.GetComponent<FGlareEffect>();

            if (clouds == null || glare == null || sunshaft == null)
                return;

            HashSet<FOceanGrid> grids = FOcean.instance.GetGrids();
            IEnumerable<Toggle> toggles = qualityGroup.ActiveToggles();
            var _e = toggles.GetEnumerator();
            if (_e.MoveNext())
            {
                switch (_e.Current.gameObject.name)
                {
                    case "Ultra":
                        if (FOcean.instance.supportSM3)
                        {
                            FOcean.instance.envParam.blendMode = eFBlendMode.Depth;
                            FOcean.instance.envParam.underWaterMode = eFUnderWaterMode.Blend;
                            sunshaft.enableShaft = true;
                            clouds.enableCloud = !FOcean.instance.mobile;
                            clouds.quality = eCLQuality.eCL_High;
                            glare.enableGlare = true;

                            if (grids != null)
                            {
                                var _ge = grids.GetEnumerator();
                                while (_ge.MoveNext())
                                {
                                    _ge.Current.baseParam.usedGridSize = FOcean.instance.mobile ? 128 : 254;
                                    _ge.Current.dwParam.mode = eFShaderMode.FFT;
                                }
                            }

                            FOcean.instance.envParam.shadowEnabled = true;
                        }


                        QualitySettings.masterTextureLimit = 0;
                        break;
                    case "High":
                        if (FOcean.instance.supportSM3)
                        {
                            FOcean.instance.envParam.blendMode = eFBlendMode.Depth;
                            FOcean.instance.envParam.underWaterMode = eFUnderWaterMode.Blend;
                            sunshaft.enableShaft = false;
                            clouds.enableCloud = !FOcean.instance.mobile;
                            clouds.quality = eCLQuality.eCL_Medium;
                            glare.enableGlare = true;

                            if (grids != null)
                            {
                                var _ge = grids.GetEnumerator();
                                while (_ge.MoveNext())
                                {
                                    _ge.Current.baseParam.usedGridSize = FOcean.instance.mobile ? 128 : 254;
                                    _ge.Current.dwParam.mode = eFShaderMode.High;
                                }
                            }

                            FOcean.instance.envParam.shadowEnabled = true;
                        }

                        QualitySettings.masterTextureLimit = 0;
                        break;
                    case "Medium":
                        if (FOcean.instance.supportSM3)
                        {
                            FOcean.instance.envParam.blendMode = eFBlendMode.Depth;
                            FOcean.instance.envParam.underWaterMode = eFUnderWaterMode.Blend;
                            sunshaft.enableShaft = false;
                            clouds.enableCloud = true;
                            clouds.quality = eCLQuality.eCL_Fast;
                            glare.enableGlare = false;

                            FOcean.instance.envParam.shadowEnabled = true;
                        }
                        else
                            FOcean.instance.envParam.blendMode = eFBlendMode.Alpha;

                        if (grids != null)
                        {
                            var _ge = grids.GetEnumerator();
                            while (_ge.MoveNext())
                            {
                                _ge.Current.baseParam.usedGridSize = 128;
                                _ge.Current.dwParam.mode = eFShaderMode.High;
                            }
                        }

                        QualitySettings.masterTextureLimit = 0;
                        break;
                    case "Fast":
                        FOcean.instance.envParam.blendMode = eFBlendMode.None;
                        FOcean.instance.envParam.shadowEnabled = false;
                        FOcean.instance.envParam.underWaterMode = FOcean.instance.supportSM3 ? eFUnderWaterMode.Blend : eFUnderWaterMode.Simple;
                        sunshaft.enableShaft = false;
                        clouds.enableCloud = false;
                        glare.enableGlare = false;

                        if (grids != null)
                        {
                            var _ge = grids.GetEnumerator();
                            while (_ge.MoveNext())
                            {
                                _ge.Current.baseParam.usedGridSize = 64;
                                _ge.Current.dwParam.mode = eFShaderMode.Fast;
                            }
                        }

                        QualitySettings.masterTextureLimit = 1;
                        break;
                }
            }
            
        }
    }
}