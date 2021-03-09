using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class DemoController : MonoBehaviour
{
    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
    }

    void OnGUI()
    {
        if (GUI.Button(new Rect(10, 50, 150, 30), "ShadowMap"))
        {
            SceneManager.LoadScene("DEMO_ShadowMap");
        }

        if (GUI.Button(new Rect(10, 90, 150, 30), "Mobile Fast Shadow"))
        {
            SceneManager.LoadScene("DEMO_MobileFastShadow");
        }

        GUI.Label(new Rect(10, 130, 200, 60), "Currect Scene:\n" + SceneManager.GetActiveScene().name);
    }
}
