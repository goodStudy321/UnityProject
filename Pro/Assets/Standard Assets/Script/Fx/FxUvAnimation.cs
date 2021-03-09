using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FxUvAnimation : MonoBehaviour
{
    #region 字段
    public float m_fScrollSpeedX = 0;
    public float m_fScrollSpeedY = 1;
    public float m_fTilingX = 1;
    public float m_fTilingY = 1;
    public float m_fOffsetX = 0;
    public float m_fOffsetY = 0;
    public bool UseSmoothDeltaTime = false;
    public bool m_bFixedTileSize = false;
    public bool m_bRepeat = true;
    public bool m_bAutoDestruct = false;



    [HideInInspector]
    private Renderer m_Renderer;
    private Vector3 m_OriginalScale = new Vector3();
    protected Vector2 m_OriginalTiling = new Vector2();
    private Vector2 m_RepeatOffset = new Vector2();
    private Vector2 m_EndOffset = new Vector2();
    #endregion

    #region 公开方法
    public void Reset()
    {
        m_fOffsetX = 0;
        m_fOffsetY = 0;

        //float offset;
        //offset = m_fOffsetX + m_fTilingX;
        //m_RepeatOffset.x = offset - (int)(offset);
        //if (m_RepeatOffset.x < 0)
        //    m_RepeatOffset.x += 1;
        //offset = m_fOffsetY + m_fTilingY;
        //m_RepeatOffset.y = offset - (int)(offset);
    }

    #endregion

    #region 私有方法

    private void Start()
    {
        m_Renderer = GetComponent<Renderer>();

        m_OriginalScale = transform.lossyScale;
        m_OriginalTiling.x = m_fTilingX;
        m_OriginalTiling.y = m_fTilingY;

        if (m_Renderer == null || m_Renderer.sharedMaterial == null || m_Renderer.sharedMaterial.mainTexture == null)
            enabled = false;
        else
        {
            float offset;
            offset = m_fOffsetX + m_fTilingX;
            m_RepeatOffset.x = offset - (int)(offset);
            if (m_RepeatOffset.x < 0)
                m_RepeatOffset.x += 1;
            offset = m_fOffsetY + m_fTilingY;
            m_RepeatOffset.y = offset - (int)(offset);
            if (m_RepeatOffset.y < 0)
                m_RepeatOffset.y += 1;
            m_EndOffset.x = 1 - (m_fTilingX - (int)(m_fTilingX) + ((m_fTilingX - (int)(m_fTilingX)) < 0 ? 1 : 0));
            m_EndOffset.y = 1 - (m_fTilingY - (int)(m_fTilingY) + ((m_fTilingY - (int)(m_fTilingY)) < 0 ? 1 : 0));

        }
    }

    private void Update()
    {
        if (m_Renderer == null || m_Renderer.sharedMaterial == null || m_Renderer.sharedMaterial.mainTexture == null)
            return;

        if (m_bRepeat == true)
            m_bAutoDestruct = false;

        if (m_bFixedTileSize)
        {
            if (m_fScrollSpeedX != 0 && m_OriginalScale.x != 0)
                m_fTilingX = m_OriginalTiling.x * (transform.lossyScale.x / m_OriginalScale.x);
            if (m_fScrollSpeedY != 0 && m_OriginalScale.y != 0)
                m_fTilingY = m_OriginalTiling.y * (transform.lossyScale.y / m_OriginalScale.y);
            m_Renderer.material.mainTextureScale = new Vector2(m_fTilingX, m_fTilingY);
        }

        if (UseSmoothDeltaTime)
        {
            m_fOffsetX += FxMamager.GetInstance().GetSmoothDeltaTime() * m_fScrollSpeedX;
            m_fScrollSpeedY += FxMamager.GetInstance().GetSmoothDeltaTime() * m_fScrollSpeedY;
        }
        else
        {
            m_fOffsetX += Time.deltaTime * m_fScrollSpeedX;
            m_fOffsetY += Time.deltaTime * m_fScrollSpeedY;
        }

        bool bCallEndAni = false;
        if (m_bRepeat == false)
        {
            m_RepeatOffset.x += Time.deltaTime * m_fScrollSpeedX;
            if (m_RepeatOffset.x < 0 || m_RepeatOffset.x > 1)
            {
                m_fOffsetX = m_EndOffset.x;
                enabled = false;
                bCallEndAni = true;
            }

            m_RepeatOffset.y += Time.deltaTime * m_fScrollSpeedY;
            if (m_RepeatOffset.y < 0 || m_RepeatOffset.y > 1)
            {
                m_fOffsetY = m_EndOffset.y;
                enabled = false;
                bCallEndAni = true;
            }
        }

        m_Renderer.material.mainTextureOffset = new Vector2(m_fOffsetX - ((int)m_fOffsetX), m_fOffsetY - ((int)m_fOffsetY));

        if (bCallEndAni == true)
        {
            if (m_bAutoDestruct)
            {
                GameObject.Destroy(this.gameObject);
            }
        }
    }
    #endregion



















}
