using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CameraBillboard : MonoBehaviour
{

    void Awake()
    {

    }
    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }

    void LateUpdate()
    {
        Camera camera = Camera.current;
        if (camera != null)
        {
            transform.rotation = Quaternion.LookRotation(camera.transform.forward);
        }
    }
}
