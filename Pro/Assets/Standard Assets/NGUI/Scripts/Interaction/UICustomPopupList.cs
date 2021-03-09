//-------------------------------------------------
//            NGUI: Next-Gen UI kit
// Copyright © 2011-2017 Tasharen Entertainment Inc
//-------------------------------------------------

using UnityEngine;
using System.Collections.Generic;
using System.Collections;

/// <summary>
/// Popup list can be used to display pop-up menus and drop-down lists.
/// </summary>

[ExecuteInEditMode]
[AddComponentMenu("NGUI/Interaction/Custom Popup List")]
public class UICustomPopupList : UIPopupList
{

    public int SpacingX = 0;
    public int SpacingY = 0;

    public string lblbgSprite;

    [HideInInspector][SerializeField] protected UIBasicSprite mLblBg;
    
    public int CustomW = 100;
    public int CustomH = 100;

    protected override Vector3 GetHighlightPosition()
    {
        if (mHighlightedLabel == null || mHighlight == null) return Vector3.zero;
        
        float offsetX = (mHighlightedLabel.printedSize.x - CustomW) * 0.5f;
        float offsetY = (CustomH - mHighlightedLabel.printedSize.y) * 0.5f;
        Vector3 pos = mHighlightedLabel.cachedTransform.localPosition + new Vector3(offsetX, offsetY, 1f);
        return pos;
    }

    public override void Show ()
	{
		if (enabled && NGUITools.GetActive(gameObject) && mChild == null && isValid && items.Count > 0)
		{
			mLabelList.Clear();
			StopCoroutine("CloseIfUnselected");

			// Ensure the popup's source has the selection
			UICamera.selectedObject = (UICamera.hoveredObject ?? gameObject);
			mSelection = UICamera.selectedObject;
			source = mSelection;

			if (source == null)
			{
				Debug.LogError("Popup list needs a source object...");
				return;
			}

			mOpenFrame = Time.frameCount;

			// Automatically locate the panel responsible for this object
			if (mPanel == null)
			{
				mPanel = UIPanel.Find(transform);
				if (mPanel == null) return;
			}

			// Calculate the dimensions of the object triggering the popup list so we can position it below it
			Vector3 min;
			Vector3 max;

			// Create the root object for the list
			mChild = new GameObject("Drop-down List");
			mChild.layer = gameObject.layer;

			if (separatePanel)
			{
				if (GetComponent<Collider>() != null)
				{
					Rigidbody rb = mChild.AddComponent<Rigidbody>();
					rb.isKinematic = true;
				}
				else if (GetComponent<Collider2D>() != null)
				{
					Rigidbody2D rb = mChild.AddComponent<Rigidbody2D>();
					rb.isKinematic = true;
				}
				
				var panel = mChild.AddComponent<UIPanel>();
				panel.depth = 1000000;
				panel.sortingOrder = mPanel.sortingOrder;
			}
			current = this;

			var pTrans = separatePanel ? ((Component)mPanel.GetComponentInParent<UIRoot>() ?? mPanel).transform : mPanel.cachedTransform;
			Transform t = mChild.transform;
			t.parent = pTrans;

			// Manually triggered popup list on some other game object
			if (openOn == OpenOn.Manual && mSelection != gameObject)
			{
				startingPosition = UICamera.lastEventPosition;
				min = pTrans.InverseTransformPoint(mPanel.anchorCamera.ScreenToWorldPoint(startingPosition));
				max = min;
				t.localPosition = min;
				startingPosition = t.position;
			}
			else
			{
				Bounds bounds = NGUIMath.CalculateRelativeWidgetBounds(pTrans, transform, false, false);
				min = bounds.min;
				max = bounds.max;
				t.localPosition = min;
				startingPosition = t.position;
			}

			StartCoroutine("CloseIfUnselected");

			t.localRotation = Quaternion.identity;
			t.localScale = Vector3.one;

			int depth = separatePanel ? 0 : NGUITools.CalculateNextDepth(mPanel.gameObject);

			// Add a sprite for the background
			if (background2DSprite != null)
			{
				UI2DSprite sp2 = mChild.AddWidget<UI2DSprite>(depth);
				sp2.sprite2D = background2DSprite;
				mBackground = sp2;
			}
			else if (atlas != null) mBackground = NGUITools.AddSprite(mChild, atlas, backgroundSprite, depth);
			else return;

			bool placeAbove = (position == Position.Above);

			if (position == Position.Auto)
			{
				UICamera cam = UICamera.FindCameraForLayer(mSelection.layer);

				if (cam != null)
				{
					Vector3 viewPos = cam.cachedCamera.WorldToViewportPoint(startingPosition);
					placeAbove = (viewPos.y < 0.5f);
				}
			}

			mBackground.pivot = UIWidget.Pivot.TopLeft;
			mBackground.color = backgroundColor;

			// We need to know the size of the background sprite for padding purposes
			Vector4 bgPadding = mBackground.border;
			mBgBorder = bgPadding.y;
            mBackground.cachedTransform.localPosition = new Vector3(-SpacingX, 0, 0f);

            // Add a sprite used for the selection
            if (highlight2DSprite != null)
			{
				UI2DSprite sp2 = mChild.AddWidget<UI2DSprite>(++depth);
				sp2.sprite2D = highlight2DSprite;
				mHighlight = sp2;
			}
			else if (atlas != null) mHighlight = NGUITools.AddSprite(mChild, atlas, highlightSprite, depth + 2);
			else return;

			//float hlspHeight = 0f, hlspLeft = 0f;

			/*if (mHighlight.hasBorder)
			{
				hlspHeight = mHighlight.border.w;
				hlspLeft = mHighlight.border.x;
			}*/

			mHighlight.pivot = UIWidget.Pivot.TopLeft;
			mHighlight.color = highlightColor;

			float fontHeight = activeFontSize;
			float dynScale = activeFontScale;
			float labelHeight = fontHeight * dynScale;
			float lineHeight = CustomH + SpacingY;
			float x = 0f, y = -SpacingY;
			float contentHeight = SpacingY;
			List<UILabel> labels = new List<UILabel>();

			// Clear the selection if it's no longer present
			if (!items.Contains(mSelectedItem))
				mSelectedItem = null;

			// Run through all items and create labels for each one
			for (int i = 0, imax = items.Count; i < imax; ++i)
            {

                mLblBg = NGUITools.AddSprite(mChild, atlas, lblbgSprite, mBackground.depth + 1);
                mLblBg.width = CustomW;
                mLblBg.height = CustomH;
                mLblBg.pivot = UIWidget.Pivot.TopLeft;
                mLblBg.transform.localPosition = new Vector3(0, y , 0);

                string s = items[i];

				UILabel lbl = NGUITools.AddWidget<UILabel>(mChild, mBackground.depth + 3);
				lbl.name = i.ToString();
				lbl.pivot = UIWidget.Pivot.TopLeft;
				lbl.bitmapFont = bitmapFont;
				lbl.trueTypeFont = trueTypeFont;
				lbl.fontSize = fontSize;
				lbl.fontStyle = fontStyle;
				lbl.text = isLocalized ? Localization.Get(s) : s;
				lbl.modifier = textModifier;
				lbl.color = textColor;
				lbl.cachedTransform.localPosition = new Vector3((CustomW - lbl.printedSize.x) * 0.5f, y - (CustomH - lbl.printedSize.y) * 0.5f, -1f);
				lbl.overflowMethod = UILabel.Overflow.ResizeFreely;
				lbl.alignment = alignment;
				labels.Add(lbl);
                mLblBg.transform.parent = lbl.transform;

                contentHeight += lineHeight;

				y -= lineHeight;
				x = Mathf.Max(x, lbl.printedSize.x);

				// Add an event listener
				UIEventListener listener = UIEventListener.Get(lbl.gameObject);
				listener.onHover = OnItemHover;
				listener.onPress = OnItemPress;
				listener.onClick = OnItemClick;
				listener.parameter = s;

				// Move the selection here if this is the right label
				if (mSelectedItem == s || (i == 0 && string.IsNullOrEmpty(mSelectedItem)))
					Highlight(lbl, true);

				// Add this label to the list
				mLabelList.Add(lbl);
			}

			// The triggering widget's width should be the minimum allowed width
			x = Mathf.Max(x, (max.x - min.x) - (bgPadding.x + padding.x) * 2f);

			//float cx = x;

            // Run through all labels and add colliders
            for (int i = 0, imax = labels.Count; i < imax; ++i)
			{
				UILabel lbl = labels[i];
				NGUITools.AddWidgetCollider(lbl.gameObject);
				lbl.autoResizeBoxCollider = false;
				BoxCollider bc = lbl.GetComponent<BoxCollider>();
                
                if (bc != null)
				{
					bc.center = new Vector3(lbl.printedSize.x, -lbl.printedSize.y, bc.center.z) * 0.5f;
					bc.size = new Vector3(CustomW, CustomH, 1f);
				}
				else
				{
					BoxCollider2D b2d = lbl.GetComponent<BoxCollider2D>();
#if UNITY_4_3 || UNITY_4_5 || UNITY_4_6 || UNITY_4_7
					b2d.center = new Vector3(lbl.printedSize.x, -lbl.printedSize.y, 0) * 0.5f;
#else
                    b2d.offset = new Vector3(lbl.printedSize.x, -lbl.printedSize.y, 0) * 0.5f;
#endif
					b2d.size = new Vector3(CustomW, CustomH, 1f);
				}
			}

			int lblWidth = Mathf.RoundToInt(x);
			x += (bgPadding.x + padding.x) * 2f;
			y -= bgPadding.y;

			// Scale the background sprite to envelop the entire set of items
			mBackground.width = Mathf.RoundToInt(CustomW + SpacingX * 2);
			mBackground.height = Mathf.RoundToInt(contentHeight);

			// Set the label width to make alignment work
			for (int i = 0, imax = labels.Count; i < imax; ++i)
			{
				UILabel lbl = labels[i];
				lbl.overflowMethod = UILabel.Overflow.ShrinkContent;
				lbl.width = lblWidth;
			}
            
			mHighlight.width = Mathf.RoundToInt(CustomW);
			mHighlight.height = Mathf.RoundToInt(CustomH);

			// If the list should be animated, let's animate it by expanding it
			if (isAnimated)
			{
				AnimateColor(mBackground);

				if (Time.timeScale == 0f || Time.timeScale >= 0.1f)
				{
					float bottom = y + labelHeight;
					Animate(mHighlight, placeAbove, bottom);
					for (int i = 0, imax = labels.Count; i < imax; ++i)
						Animate(labels[i], placeAbove, bottom);
					AnimateScale(mBackground, placeAbove, bottom);
				}
			}

			// If we need to place the popup list above the item, we need to reposition everything by the size of the list
			if (placeAbove)
			{
				min.y = max.y + bgPadding.y;
				max.y = min.y + mBackground.height;
				max.x = min.x + mBackground.width;
				t.localPosition = new Vector3(min.x, max.y - bgPadding.y, min.z);
			}
			else
			{
				max.y = min.y + bgPadding.y;
				min.y = max.y - mBackground.height;
				max.x = min.x + mBackground.width;
			}

			Transform pt = mPanel.cachedTransform.parent;

			if (pt != null)
			{
				min = mPanel.cachedTransform.TransformPoint(min);
				max = mPanel.cachedTransform.TransformPoint(max);
				min = pt.InverseTransformPoint(min);
				max = pt.InverseTransformPoint(max);
			}

			// Ensure that everything fits into the panel's visible range
			Vector3 offset = mPanel.hasClipping ? Vector3.zero : mPanel.CalculateConstrainOffset(min, max);
			Vector3 pos = t.localPosition + offset;
			pos.x = Mathf.Round(pos.x);
			pos.y = Mathf.Round(pos.y);
			t.localPosition = pos;
		}
		else OnSelect(false);
	}
}
