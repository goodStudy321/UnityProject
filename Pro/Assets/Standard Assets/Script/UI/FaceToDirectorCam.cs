using UnityEngine;
using System.Collections;
using Slate;

public class FaceToDirectorCam : MonoBehaviour
{
    private Transform target;
    private Transform m_Transform;

    void Awake()
    {
        m_Transform = GetComponent<Transform>();
    }

    private void OnEnable()
    {
        target = DirectorCamera.current.cam.transform;
    }

    void Update()
    {
        if (target == null)
            return;

        m_Transform.LookAt(target);
    }
}