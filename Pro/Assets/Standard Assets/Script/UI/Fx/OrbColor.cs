using UnityEngine;
using UnityEngine.UI;

namespace guiraffe.SubstanceOrb
{
    [RequireComponent(typeof(Renderer))]
    public class OrbColor : OrbBehaviour
    {
        public float AnimationSpeed = 2.0f;

        public Color SurfaceColor = Color.white;
        public Color AccentColor = Color.white;
        public Color BaseColor = Color.white;

        Color startSurfaceColor;
        Color startAccentColor;
        Color startBaseColor;

        void Awake()
        {
            startSurfaceColor = Material.GetColor(OrbVariable.SURFACE_COLOR);
            startAccentColor = Material.GetColor(OrbVariable.ACCENT_COLOR);
            startBaseColor = Material.GetColor(OrbVariable.BASE_COLOR);
        }

        void OnDestroy()
        {
            SetColors(startSurfaceColor, startAccentColor, startBaseColor);
        }

        void Update()
        {
            Color currentSurfaceColor = Material.GetColor(OrbVariable.SURFACE_COLOR);
            Color currentAccentColor = Material.GetColor(OrbVariable.ACCENT_COLOR);
            Color currentBaseColor = Material.GetColor(OrbVariable.BASE_COLOR);
            float rate = Time.deltaTime * AnimationSpeed;
            SetColors(Color.Lerp(currentSurfaceColor, SurfaceColor, rate), Color.Lerp(currentAccentColor, AccentColor, rate), Color.Lerp(currentBaseColor, BaseColor, rate));
        }

        void SetColors(Color surfaceColor, Color accentColor, Color baseColor)
        {
            Material.SetColor(OrbVariable.SURFACE_COLOR, surfaceColor);
            Material.SetColor(OrbVariable.ACCENT_COLOR, accentColor);
            Material.SetColor(OrbVariable.BASE_COLOR, baseColor);
        }

        public void GetFromMaterial()
        {
            if (Application.isPlaying)
            {
                Debug.LogWarning("GetFromMaterial() should be used only in edit mode. Nothing will happen.");
                return;
            }

            SurfaceColor = Material.GetColor(OrbVariable.SURFACE_COLOR);
            AccentColor = Material.GetColor(OrbVariable.ACCENT_COLOR);
            BaseColor = Material.GetColor(OrbVariable.BASE_COLOR);
        }

        public void ApplyToMaterial()
        {
            if (Application.isPlaying)
            {
                Debug.LogWarning("ApplyToMaterial() should be used only in edit mode. Nothing will happen.");
                return;
            }

            SetColors(SurfaceColor, AccentColor, BaseColor);
        }
    }
}