using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using UnityEngine.Events;
using UnityEngine.EventSystems;

namespace FastOcean
{
    [RequireComponent(typeof(RectTransform))]
    public class JoyStick : Selectable, IBeginDragHandler, IEndDragHandler, IDragHandler
    {
        [SerializeField]
        RectTransform _joystickGraphic;
        public RectTransform JoystickGraphic
        {
            get { return _joystickGraphic; }
            set
            {
                _joystickGraphic = value;
                UpdateJoystickGraphic();
            }
        }

        Vector2 _axis;

        float _spring = 25;
        bool Is_stop = false;
        public float Spring
        {
            get { return _spring; }
            set { _spring = value; }
        }

        [SerializeField]
        float _deadZone = .1f;
        public float DeadZone
        {
            get { return _deadZone; }
            set { _deadZone = value; }
        }

        public AnimationCurve outputCurve = new AnimationCurve(new Keyframe(0, 0, 1, 1), new Keyframe(1, 1, 1, 1));

        public JoyStickMoveEvent OnValueChange;

        public Vector2 JoystickAxis
        {
            get
            {
                Vector2 outputPoint = _axis.magnitude > _deadZone ? _axis : Vector2.zero;
                float magnitude = outputPoint.magnitude;

                outputPoint *= outputCurve.Evaluate(magnitude);

                return outputPoint;
            }
            set { SetAxis(value); }
        }

        RectTransform _rectTransform;
        public RectTransform rectTransform
        {
            get
            {
                if (!_rectTransform) _rectTransform = transform as RectTransform;

                return _rectTransform;
            }
        }

        bool _isDragging;
        bool _isKeyPressed;

        bool dontCallEvent;
        public delegate void JoyStickMove(Vector2 move);

        public static event JoyStickMove On_JoystickMove = null;
        public static event JoyStickMove On_JoystickEnd = null;


        public void OnBeginDrag(PointerEventData eventData)
        {
            if (!IsActive())
                return;

            EventSystem.current.SetSelectedGameObject(gameObject, eventData);

            Vector2 newAxis = transform.InverseTransformPoint(eventData.position);

            newAxis.x /= rectTransform.sizeDelta.x * .5f;
            newAxis.y /= rectTransform.sizeDelta.y * .5f;

            SetAxis(newAxis);

            _isDragging = true;
            dontCallEvent = true;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            _isDragging = false;
            _axis.x = 0;
            _axis.y = 0;
            SetAxis(_axis);
        }

        public void OnDrag(PointerEventData eventData)
        {
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, eventData.position, eventData.pressEventCamera, out _axis);

            _axis.x /= rectTransform.sizeDelta.x * .5f;
            _axis.y /= rectTransform.sizeDelta.y * .5f;

            SetAxis(_axis);

            dontCallEvent = true;
        }

        void OnDeselect()
        {
            _isDragging = false;
        }

        public override void OnPointerDown(PointerEventData eventData)
        {
            if (!IsActive())
                return;

            _isDragging = true;
            dontCallEvent = true;
            OnDrag(eventData);
        }

        public override void OnPointerUp(PointerEventData eventData)
        {
            _isDragging = false;

            if (On_JoystickEnd != null)
                On_JoystickEnd(_axis);
        }

        void Update()
        {
            if (_isDragging)
            {
                if (On_JoystickMove != null)
                    On_JoystickMove(_axis);
            }
            else
            {
                _axis.x = 0;
                _axis.y = 0;
                _isKeyPressed = false;
                SetAxis(_axis);
                
                if (_isDragging || _isKeyPressed)
                    if (!dontCallEvent)
                        if (OnValueChange != null) OnValueChange.Invoke(JoystickAxis);

                if ((Mathf.Abs(_axis.x) > 0.05f || Mathf.Abs(_axis.y) > 0.05f))
                {

                    if (On_JoystickMove != null)
                        On_JoystickMove(_axis);
                    Is_stop = true;
                }
                else
                {
                    if (On_JoystickEnd != null && Is_stop)
                    {
                        Is_stop = false;
                        On_JoystickEnd(_axis);
                    }

                }
            }

        }

        void LateUpdate()
        {
            if (!_isDragging && !_isKeyPressed)
                if (_axis != Vector2.zero)
                {
                    Vector2 newAxis = _axis - (_axis * Time.unscaledDeltaTime * _spring);

                    if (newAxis.sqrMagnitude <= .0001f)
                        newAxis = Vector2.zero;

                    SetAxis(newAxis);
                }

            dontCallEvent = false;
        }


        public void SetAxis(Vector2 axis)
        {
            _axis = Vector2.ClampMagnitude(axis, 1);

            Vector2 outputPoint = _axis.magnitude > _deadZone ? _axis : Vector2.zero;
            float magnitude = outputPoint.magnitude;

            outputPoint *= outputCurve.Evaluate(magnitude);

            if (!dontCallEvent)
                if (OnValueChange != null)
                    OnValueChange.Invoke(outputPoint);

            UpdateJoystickGraphic();
        }

        void UpdateJoystickGraphic()
        {
            if (_joystickGraphic)
                _joystickGraphic.localPosition = _axis * Mathf.Max(rectTransform.sizeDelta.x, rectTransform.sizeDelta.y) * .5f;
        }

        public class JoyStickMoveEvent : UnityEvent<Vector2> { }
    }
}
