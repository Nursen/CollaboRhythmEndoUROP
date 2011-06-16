/**
 * Copyright 2011 John Moore, Scott Gilroy
 *
 * This file is part of CollaboRhythm.
 *
 * CollaboRhythm is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later
 * version.
 *
 * CollaboRhythm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with CollaboRhythm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
package collaboRhythm.shared.controller.apps
{

    import collaboRhythm.shared.model.Account;
    import collaboRhythm.shared.model.CollaborationRoomNetConnectionServiceProxy;
    import collaboRhythm.shared.model.User;
    import collaboRhythm.shared.model.services.IComponentContainer;
    import collaboRhythm.shared.model.settings.Settings;
    import collaboRhythm.shared.view.BitmapCopyComponent;

    import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.EventDispatcher;
    import flash.events.MouseEvent;
    import flash.events.TransformGestureEvent;
    import flash.geom.Point;
    import flash.utils.getQualifiedClassName;

    import mx.controls.Image;
    import mx.core.DragSource;
    import mx.core.IUIComponent;
    import mx.core.IVisualElement;
    import mx.core.IVisualElementContainer;
    import mx.core.UIComponent;
    import mx.effects.Parallel;
    import mx.events.DragEvent;
    import mx.events.EffectEvent;
    import mx.graphics.ImageSnapshot;
    import mx.managers.DragManager;

	import spark.components.Application;

	import spark.components.Button;
    import spark.components.Window;
    import spark.effects.*;
    import spark.layouts.supportClasses.LayoutBase;
    import spark.primitives.Rect;

    /**
	 * Represents an instance of a workstation app which can be used to view and/or manipulate some aspect of a health record
	 * in a collaborative (or solo) work session. Workstation apps can have a mini "widget" view and a larger "full"
	 * view.
	 */	
	public class WorkstationAppControllerBase extends EventDispatcher
	{
		public static const WIDGET_WATERMARK_ALPHA:Number = 0.2;
		public static const DEBUG_BUTTON_ALPHA:Number = 0.2;
		public static const DEBUG_BUTTON_VISIBLE:Boolean = false;
		public static const PREVENT_RE_SHOWING_FULL_VIEW:Boolean = true;
		
		protected var _widgetParentContainer:IVisualElementContainer;
		protected var _widgetParentContainerLayout:LayoutBase;
		protected var _fullParentContainer:IVisualElementContainer;
//		protected var _healthRecordService:CommonHealthRecordService;
		protected var _user:User;
		protected var _collaborationRoomNetConnectionServiceProxy:CollaborationRoomNetConnectionServiceProxy;
		
		private var _topSpaceTransitionComponent:UIComponent;
		private var _centerSpaceTransitionComponent:UIComponent;
		
		private var _name:String;
		private var _modality:String;
        protected var _activeAccount:Account;
        protected var _activeRecordAccount:Account;
        protected var _settings:Settings;
        protected var _componentContainer:IComponentContainer;
		protected var _primaryShowFullViewParallelEffect:Parallel;
		protected var _secondaryShowFullViewParallelEffect:Parallel;

		public function WorkstationAppControllerBase(constructorParams:AppControllerConstructorParams)
		{
			name = defaultName;

			_widgetParentContainer = constructorParams.widgetParentContainer;
			_fullParentContainer = constructorParams.fullParentContainer;
			_modality = constructorParams.modality;
            _activeAccount = constructorParams.activeAccount;
            _activeRecordAccount = constructorParams.activeRecordAccount;
            _settings = constructorParams.settings;
            _componentContainer = constructorParams.componentContainer;

			initializeShowFullViewParallelEffects();

			createAndPrepareWidgetView();
			
			if (widgetView)
				showWidgetAsDraggable(fullView != null);
		}

		public function get isWorkstationMode():Boolean
		{
			return _modality == Settings.MODALITY_WORKSTATION;
		}

		public function get isMobileMode():Boolean
		{
			return _modality == Settings.MODALITY_MOBILE;
		}

		public function get isTabletMode():Boolean
		{
			return _modality == Settings.MODALITY_TABLET;
		}

		public function createAndPrepareWidgetView():void
		{
			if (_widgetParentContainer && !widgetView)
			{
				widgetView = createWidgetView();
				this.prepareWidgetView();
			}
		}

		public function get widgetParentContainer():IVisualElementContainer
		{
			return _widgetParentContainer;
		}

		public function set widgetParentContainer(value:IVisualElementContainer):void
		{
			_widgetParentContainer = value;
		}

		public function get defaultName():String
		{
			return null;
		}
		
		public function get name():String
		{
			return _name;
		}

		public function set name(value:String):void
		{
			_name = value;
		}

		/**
		 * Temporary instance of the view used in the top space for transition effect when showing the full view.  
		 */
		public function get topSpaceTransitionComponent():UIComponent
		{
			return _topSpaceTransitionComponent;
		}

		public function set topSpaceTransitionComponent(value:UIComponent):void
		{
			if (_topSpaceTransitionComponent != null)
			{
				removeFromParent(_topSpaceTransitionComponent);
			}	
			_topSpaceTransitionComponent = value;
		}
		
		/**
		 * Temporary instance of the view used in the center space for transition effect when showing the full view.  
		 */
		public function get centerSpaceTransitionComponent():UIComponent
		{
			return _centerSpaceTransitionComponent;
		}

		public function set centerSpaceTransitionComponent(value:UIComponent):void
		{
			if (_centerSpaceTransitionComponent != null)
			{
				removeFromParent(_centerSpaceTransitionComponent);
			}	
			_centerSpaceTransitionComponent = value;
		}
		
		public function removeFromParent(component:UIComponent):void
		{
			if (component != null)
			{
				var element:IVisualElement = component;
				if (element != null)
				{
					var parentContainer:IVisualElementContainer = component.parent as IVisualElementContainer;
					if (parentContainer != null)
						parentContainer.removeElement(element);
				}
				
				if (component.parent != null)
					component.parent.removeChild(component);
			}
		}

		public function get widgetView():UIComponent
		{
			return null;
		}

		public function set widgetView(value:UIComponent):void
		{
		}

		public function get fullView():UIComponent
		{
			return null;
		}

		public function set fullView(value:UIComponent):void
		{
		}
		
//		public function get healthRecordService():CommonHealthRecordService
//		{
//			return _healthRecordService;
//		}

//		public function set healthRecordService(value:CommonHealthRecordService):void
//		{
//			_healthRecordService = value;
//		}

		public function get user():User
		{
			return _user;
		}

		public function set user(value:User):void
		{
			_user = value;
		}
		
		public function get collaborationRoomNetConnectionServiceProxy():CollaborationRoomNetConnectionServiceProxy
		{
			return _collaborationRoomNetConnectionServiceProxy;
		}
		
		public function set collaborationRoomNetConnectionServiceProxy(value:CollaborationRoomNetConnectionServiceProxy):void
		{
			_collaborationRoomNetConnectionServiceProxy = value;
		}
		
		/**
		 * Factory method to create an instance of the widget view associated with this app.
		 * Note that this instance may or may not be used as the main instance corresponding to the "widgetView" property.
		 * @return a new instance of the corresponding widget view component
		 */
		protected function createWidgetView():UIComponent
		{
			return null;
		}
		
		/**
		 * Factory method to create an instance of the full view associated with this app.
		 * Note that this instance may or may not be used as the main instance corresponding to the "fullView" property.
		 * @return a new instance of the corresponding full view component
		 */
		protected function createFullView():UIComponent
		{
			return null;
		}

		/**
		 * Prepares the widget view for use. 
		 */
		protected function prepareWidgetView():void
		{
			if (widgetView != null)
			{
				widgetView.addEventListener(MouseEvent.CLICK, widgetClickHandler);
				widgetView.addEventListener(MouseEvent.MOUSE_DOWN, widgetMouseDownHandler);

				widgetView.visible = false;
				_widgetParentContainer.addElement(widgetView);
			}
		}
		
		/**
		 * Prepares the fullView for use. 
		 */
		protected function prepareFullView():void
		{
			if (fullView != null)
			{
				_primaryShowFullViewParallelEffect.stop();
				_secondaryShowFullViewParallelEffect.stop();
				fullView.visible = false;
				if (fullView.parent == null)
					_fullParentContainer.addElement(fullView);
			}
		}
		
		public function get isFullViewSupported():Boolean
		{
			return false;
		}
		
		public function canShowFullView():Boolean
		{
			if (!isFullViewSupported || (topSpaceTransitionComponent != null && topSpaceTransitionComponent.visible))
				return false;
			
			if (PREVENT_RE_SHOWING_FULL_VIEW)
			{
				var selected:Boolean = widgetView.getStyle("selected") as Boolean;
				return !selected;
			}
			else
				return true;
		}
		
		public function beginDrag(mouseEvent:MouseEvent):void
		{
			if (mouseEvent.buttonDown)
			{
				if (canShowFullView())
				{
					showWidgetAsDraggable(false);
					showWidgetAsSelected(true);
					
					// the drag initiator is the object being dragged (target of the mouse event)
					var dragInitiator:IUIComponent = mouseEvent.currentTarget as IUIComponent;
					
					// the drag source contains data about what's being dragged
					var dragSource:DragSource = new DragSource();
					dragSource.addData(new WorkstationAppDragData(mouseEvent), WorkstationAppDragData.DRAG_SOURCE_DATA_FORMAT);
					
					// ask the DragManger to begin the drag
					DragManager.doDrag(dragInitiator, dragSource, mouseEvent, this.createWidgetView());
				}
			}
		}
		
		public function showWidgetAsDraggable(value:Boolean):void
		{
			if (widgetView)
				widgetView.setStyle("dropShadowVisible", value);
		}
		
		public function showWidgetAsSelected(value:Boolean):void
		{
			if (widgetView)
				widgetView.setStyle("selected", value);
		}
		
		public function makeDroppable( component:IUIComponent ):void
		{
			// a dragEnter event occurs when a draggable is over a droppable
			component.addEventListener( DragEvent.DRAG_ENTER, allowDrop );
			
			// a dragDrop event occurs when a draggable is dropped
			component.addEventListener( DragEvent.DRAG_DROP, acceptDrop );
			
			component.addEventListener(DragEvent.DRAG_EXIT, dragExitHandler);
			
			component.addEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
		}
		
		public function dragCompleteHandler(dragEvent:DragEvent):void
		{
			var dragSource:DragSource = dragEvent.dragSource;
			var dragInitiator:IUIComponent = dragEvent.dragInitiator;
			var dropTarget:Object = dragEvent.currentTarget;
			
			trace( "Drag Complete ("+dragInitiator.name +") to ("+dropTarget.name +") " + dragEvent.delta );
			
			var data:WorkstationAppDragData = dragSource.dataForFormat(WorkstationAppDragData.DRAG_SOURCE_DATA_FORMAT) as WorkstationAppDragData;
			var startRect:Rect;
			if (data != null)
			{
				startRect = new Rect();
				startRect.x = dragEvent.localX - data.mouseEvent.localX;
				startRect.y = dragEvent.localY - data.mouseEvent.localY;
				
			}
			this.dispatchEvent(new WorkstationAppEvent(WorkstationAppEvent.SHOW_FULL_VIEW, this, startRect));
		}
		
		public function dragExitHandler(dragEvent:DragEvent):void
		{
			var dragSource:DragSource = dragEvent.dragSource;
			var dragInitiator:IUIComponent = dragEvent.dragInitiator;
			var dropTarget:Object = dragEvent.currentTarget;
			
			trace( "Drag Exit ("+dragInitiator.name +") to ("+dropTarget.name +")" );
		}
		
		public function allowDrop( dragEvent:DragEvent ):void
		{
			// the drop target
			var dropTarget:IUIComponent = dragEvent.currentTarget as IUIComponent;
			
			// signal to the drop manager that this will accept the item
			DragManager.acceptDragDrop(dropTarget);
			
			DragManager.showFeedback(DragManager.MOVE);
		}
		
		public function acceptDrop( dragEvent:DragEvent ):void
		{
			var dragSource:DragSource = dragEvent.dragSource;
			var dragInitiator:IUIComponent = dragEvent.dragInitiator;
			var dropTarget:Object = dragEvent.currentTarget;
			
			trace( "Dragged ("+dragInitiator.name +") to ("+dropTarget.name +") and Dropped" );
		}
		
		private function widgetDragCompleteHandler(event:DragEvent):void
		{
			
		}
		
		private function widgetPanHandler(e:TransformGestureEvent):void
		{
			trace("On pan... " + e.phase + " " + e.offsetX + " offset Y " + e.offsetY);
//			var prevPoint:Point = new Point(img.x,img.y);
//			img.x += e.offsetX*3;
//			img.y += e.offsetY*3;
			
//			if (e.phase == GesturePhase.END && Math.abs(e.offsetX) < 100 && e.offsetY < -20)
//				this.dispatchEvent(new WorkstationAppEvent(WorkstationAppEvent.SHOW_FULL_VIEW, this));
		}
		
		private function widgetDoubleClickHandler(event:MouseEvent):void
		{
			if (canShowFullView())
				this.dispatchEvent(new WorkstationAppEvent(WorkstationAppEvent.SHOW_FULL_VIEW, this));
		}

		protected function get shouldShowFullViewOnWidgetClick():Boolean
		{
			return isWorkstationMode || isTabletMode;
		}
		
		private function widgetClickHandler(event:MouseEvent):void
		{
			if (shouldShowFullViewOnWidgetClick && canShowFullView() && isShowFullViewClickEvent(event))
				this.dispatchEvent(new WorkstationAppEvent(WorkstationAppEvent.SHOW_FULL_VIEW, this));
		}
		
		private function isShowFullViewClickEvent(event:MouseEvent):Boolean
		{
			// ignore all events for buttons (such as buttons in scroll bars)
			if (event.target is Button || event.target is mx.controls.Button)
			{
				return false;
			}
			
			return true;
		}
		
		private function widgetMouseDownHandler(event:MouseEvent):void
		{
			if (canShowFullView())
				showWidgetAsDraggable(false);
		}
		
		public function get parentContainer():IVisualElementContainer
		{
			return _widgetParentContainer;
		}

		public function set parentContainer(value:IVisualElementContainer):void
		{
			_widgetParentContainer = value;
		}
		
		public function showWidget(left:Number=-1, top:Number=-1):void
		{
			if (widgetView)
			{
				if (left != -1 && top != -1)
					widgetView.move(left, top);

				widgetView.visible = true;
			}
		}
		
		/**
		 * Converts from the local coordinate system of the "from" component to the local coordinate system of the "to" component.
		 * Will convert values correctly even if the two components are from different stages (different windows). 
		 * @param from Component to use for the "from" the local coordinates  
		 * @param to
		 * @return A point in the coordinate system of the "to" component.
		 * 
		 */
		public static function localToLocal(from:UIComponent, to:UIComponent, fromPoint:Point=null):Point
		{
			if (fromPoint == null)
				fromPoint = new Point(0,0);
			
			var globalPoint:Point = from.localToGlobal(fromPoint);

			if (from.stage != to.stage)
			{
				globalPoint.x += from.stage.nativeWindow.x;
				globalPoint.y += from.stage.nativeWindow.y;
				globalPoint.x -= to.stage.nativeWindow.x;
				globalPoint.y -= to.stage.nativeWindow.y;
			}
			return to.globalToLocal(globalPoint);
		}
		
		private function applyShowFullViewEffects(parallel:Parallel, view:UIComponent, startRect:Rect, shouldResize:Boolean):void
		{
			if (_traceEventHandlers)
				trace(this + ".applyShowFullViewEffects");

			const duration:Number = 1000;

			parallel.stop();

			// move to the front and make visible
			var viewParent:IVisualElementContainer = view.parent as IVisualElementContainer;
			if (viewParent != null)
				viewParent.setElementIndex(view, viewParent.numElements - 1);
			view.visible = true;
			
			parallel.target = view;
			parallel.children = new Array();

			var move:Move = new Move(view);
			parallel.addChild(move);
			var fromPosition:Point;
			
			if (startRect != null)
				fromPosition = localToLocal(widgetView, view, new Point(startRect.x, startRect.y));
			else
				fromPosition = localToLocal(widgetView, view);

			var startRectLocal:Rect = new Rect();
			startRectLocal.x = fromPosition.x;
			startRectLocal.y = fromPosition.y;

			if (shouldResize)
			{
				startRectLocal.width = widgetView.width;
				startRectLocal.height = widgetView.height;

				shrinkRectToAspectRatio(startRectLocal, fullView);
			}

			var toPosition:Point = localToLocal(_fullParentContainer as UIComponent, view);
			
			if (!shouldResize)
			{
				// make the toPosition centered on the _fullParentContainer
				toPosition.x += (_fullParentContainer as UIComponent).width / 2;
				toPosition.y += (_fullParentContainer as UIComponent).height / 2;

				toPosition.x -= view.width / 2;
				toPosition.y -= view.height / 2;
			}
			
			move.xFrom = startRectLocal.x;
			move.yFrom = startRectLocal.y;
			move.xTo = toPosition.x;
			move.yTo = toPosition.y;
			move.duration = duration;

			if (shouldResize)
			{
				var resize:Resize = new Resize(view);
				parallel.addChild(resize);
				resize.widthFrom = startRectLocal.width;
				resize.heightFrom = startRectLocal.height;
				resize.widthTo = (_fullParentContainer as UIComponent).width;
				resize.heightTo = (_fullParentContainer as UIComponent).height;
				resize.duration = duration;
//				resize.play();
				
				var scale:Scale = new Scale(view);
				parallel.addChild(scale);
				scale.scaleXFrom = resize.widthFrom / resize.widthTo;
				scale.scaleYFrom = resize.heightFrom / resize.heightTo;
				scale.scaleXTo = getEffectiveScaleX(_fullParentContainer as UIComponent);
				scale.scaleYTo = getEffectiveScaleY(_fullParentContainer as UIComponent);
				scale.duration = duration;
//				scale.play();
			}
			
			var fade:Fade = new Fade(view);
			parallel.addChild(fade);
			fade.alphaFrom = 0.5;
			fade.alphaTo = 1;
			fade.duration = duration;
//			fade.play();
			
			parallel.play();
		}

		private function initializeShowFullViewParallelEffects():void
		{
			_primaryShowFullViewParallelEffect = new Parallel();
			_primaryShowFullViewParallelEffect.addEventListener(EffectEvent.EFFECT_END, primaryShowFullViewParallelEffect_effectEndHandler, false, 0, true);
			_secondaryShowFullViewParallelEffect = new Parallel();
		}
		
		private function getEffectiveScaleX(component:UIComponent):Number
		{
			var current:UIComponent = component;
			
			var scale:Number = 1;
			
			// walk up the component hierarchy to include scale
			while (current != null)
			{
				scale *= current.scaleX;
				current = current.parent as UIComponent;
			}
			
			return scale;
		}
		
		private function getEffectiveScaleY(component:UIComponent):Number
		{
			var current:UIComponent = component;
			
			var scale:Number = 1;
			
			// walk up the component hierarchy to include scale
			while (current != null)
			{
				scale *= current.scaleY;
				current = current.parent as UIComponent;
			}
			
			return scale;
		}
		
		public function showFullView(startRect:Rect):void
		{
			if (_fullParentContainer && fullView == null)
			{
				fullView = createFullView();
				this.prepareFullView();
			}
			
			if (canShowFullView())
			{
				showFullViewStart();
				
				showWidgetAsDraggable(false);
				showWidgetAsSelected(true);
				
				_primaryShowFullViewParallelEffect.stop();
				_secondaryShowFullViewParallelEffect.stop();

				fullView.validateNow();
				var bitmapData:BitmapData = ImageSnapshot.captureBitmapData(fullView);
				
				topSpaceTransitionComponent = BitmapCopyComponent.createFromBitmap(bitmapData, fullView);
				centerSpaceTransitionComponent = BitmapCopyComponent.createFromBitmap(bitmapData, fullView);
				
				fullView.visible = false;
				var widgetTransitionComponentContainer:IVisualElementContainer = getTransitionComponentContainer(widgetView);

				if (isWorkstationMode || isTabletMode)
				{
					if (topSpaceTransitionComponent != null)
					{
						widgetTransitionComponentContainer.addElement(topSpaceTransitionComponent);
						
						applyShowFullViewEffects(_primaryShowFullViewParallelEffect, topSpaceTransitionComponent, startRect, true);
					}
					
					var fullTransitionComponentContainer:IVisualElementContainer = getTransitionComponentContainer(fullView);

					if (centerSpaceTransitionComponent != null && widgetTransitionComponentContainer != fullTransitionComponentContainer)
					{
						fullTransitionComponentContainer.addElement(centerSpaceTransitionComponent);
						
						applyShowFullViewEffects(_secondaryShowFullViewParallelEffect, centerSpaceTransitionComponent, startRect, true);
					}
				}
				else
				{
					fullView.visible = true;
					hideOtherFullViews();
					showFullViewComplete();
				}
			}
		}

		private function shrinkRectToAspectRatio(rect:Rect, targetView:UIComponent):void
		{
			if (rect.height > 0 && targetView.height > 0)
			{
				var rectRatio:Number = rect.width / rect.height;
				var targetRatio:Number = targetView.width / targetView.height;

				if (targetRatio > rectRatio)
				{
					// target is wider, so reduce rect height
					var newHeight:Number = rect.width / targetRatio;
					rect.y += (rect.height - newHeight) / 2;
					rect.height = newHeight;
				}
				else
				{
					// target is taller, so reduce rect width
					var newWidth:Number = rect.height * targetRatio;
					rect.x += (rect.width - newWidth) / 2;
					rect.width = newWidth;
				}
			}
		}

		private function getTransitionComponentContainer(widgetView:UIComponent):IVisualElementContainer
		{
			var container:DisplayObjectContainer = widgetView.parent;
			if (!container)
				throw new Error("Failed to find a container to put the transition component in");

			while (container.parent != null && !(container is Window) && !(container is Application))
			{
				container = container.parent;
			}

			if (container is IVisualElementContainer)
				return container as IVisualElementContainer;
			else
				throw new Error("Failed to find a IVisualElementContainer to put the transition component in");
		}
		
		/**
		 * Called at the beginning when showing a full view (before transition animations). Override in subclasses to change behavior for showing full view.
		 */
		protected function showFullViewStart():void
		{
		}
		
		/**
		 * Called at the end when showing a full view (after transition animations). Override in subclasses to change behavior for showing full view.
		 */
		protected function showFullViewComplete():void
		{
		}
		
		private var _traceEventHandlers:Boolean = false;

		public function primaryShowFullViewParallelEffect_effectEndHandler(event:EffectEvent):void
		{
			if (_traceEventHandlers)
				trace(this + ".primaryShowFullViewParallelEffect_effectEndHandler");
			
			fullView.alpha = 1;
			fullView.visible = true;
			
			hideOtherFullViews();
			
			removeFromParent(topSpaceTransitionComponent);
			topSpaceTransitionComponent = null;
			
			removeFromParent(centerSpaceTransitionComponent);
			centerSpaceTransitionComponent = null;
			
			showFullViewComplete();
		}
		
		private function hideOtherFullViews():void
		{
			var fullViewParent:IVisualElementContainer = (fullView.parent as IVisualElementContainer);
			for (var i:int = 0; i < fullViewParent.numElements; i++)
			{
				var child:IUIComponent = fullViewParent.getElementAt(i) as IUIComponent;
				if (child != null && child != fullView)
				{
					child.visible = false;
				}
			}
		}

		public function hideFullView():void
		{
			_primaryShowFullViewParallelEffect.stop();
			_secondaryShowFullViewParallelEffect.stop();

			showWidgetAsDraggable(fullView != null);
			showWidgetAsSelected(false);
			if (fullView != null && fullView.visible)
			{
//				var move:Move = new Move(fullView);
//				move.xFrom = 0;
//				move.xTo = (_fullParentContainer as UIComponent).width / 2;
//				move.yFrom = 0;
//				move.yTo = -(_fullParentContainer as UIComponent).height;
//				move.play();
//				
//				var resize:Resize = new Resize(fullView);
//				resize.widthFrom = (_fullParentContainer as UIComponent).width;
//				resize.widthTo = SHRINK_WIDTH;
//				resize.heightFrom = (_fullParentContainer as UIComponent).height;
//				resize.heightTo = SHRINK_HEIGHT;
//				resize.play();

				// Use an effect to keep this fullView visible while showing the next full view (of another app)
				if (isWorkstationMode)
				{
					var fade:Fade = new Fade(fullView);
					fade.alphaFrom = 1;
					fade.alphaTo = 1;
					fade.duration = 1500;
					fade.play();
					fade.addEventListener(EffectEvent.EFFECT_END, hideFullViewFadeEndHandler, false, 0, true);
				}
				else
				{
					fullView.visible = false;
					hideFullViewComplete();
				}
			}
			else
			{
				//trace("hideFullView() called but fullView is null");
			}
		}

		public function hideFullViewFadeEndHandler(event:EffectEvent):void
		{
			fullView.visible = false;
			hideFullViewComplete();
		}
		
		/**
		 * Called after hiding the full view is complete. Override in subclasses to change behavior for hiding full view.
		 */
		protected function hideFullViewComplete():void
		{
		}
		
		/**
		 * Removes the widget and full views from their respective parents and sets the corresponding references to null
		 * to allow for garbage collection. This method is called when the view(s) for the app are no longer needed.
		 * Any model or view state data that this app needs (perhaps in user.appData) should NOT be removed here because
		 * the view(s) may be subsequently re-created and their state should be restored if this happens.
		 * <p>
		 * Subclasses may override this and provide additional cleanup if required
		 * before or after super.destroyViews().  
		 * 
		 */
		public function destroyViews():void
		{
			// TODO: ensure that the views are completely destructed and removed from memory (remove and references, event listeners)
			_primaryShowFullViewParallelEffect.stop();
			_secondaryShowFullViewParallelEffect.stop();

			if (widgetView != null && widgetView.parent != null)
			{
				if (widgetView.parent is IVisualElementContainer)
					(widgetView.parent as IVisualElementContainer).removeElement(widgetView);
				else
					widgetView.parent.removeChild(widgetView);
				
			}
			
			if (widgetView)
			{
				widgetView.removeEventListener(MouseEvent.CLICK, widgetClickHandler);
				widgetView.removeEventListener(MouseEvent.MOUSE_DOWN, widgetMouseDownHandler);
				widgetView.accessibilityProperties = null;
				widgetView = null;
			}
			
			if (fullView != null && fullView.parent != null)
			{
				if (fullView.parent is IVisualElementContainer)
					(fullView.parent as IVisualElementContainer).removeElement(fullView);
				else
					fullView.parent.removeChild(fullView);
			}
			
			if (fullView)
			{
				fullView.accessibilityProperties = null;
				fullView = null;
			}
		}
		
		/**
		 * Initializes the app. Called after standard properties (healthRecordService, user, etc) are set so
		 * that the app can be prepared for use. 
		 */
		public function initialize():void
		{
		}
		
		public function reloadUserData():void
		{
			// to be implemented by subclasses
		}
		
		public function close():void
		{
			destroyViews();
			removeUserData();
		}
		
		/**
		 * Removes any references to user data owned by this app on the User object.
		 * This is called when closing the user/record and/or when closing or reloading the whole application.
		 * <p>
		 * Sublcasses should override this method if they have added any data to the User, such as on User.appData.
		 */
		protected function removeUserData():void
		{
			// to be implemented by subclasses
		}

		public function get appClassName():String
		{
			return getQualifiedClassName(this);
		}

        public function get activeAccount():Account {
            return _activeAccount;
        }

        public function set activeAccount(value:Account):void {
            _activeAccount = value;
        }

        public function get activeRecordAccount():Account
        {
            return _activeRecordAccount;
        }

        public function set activeRecordAccount(value:Account):void
        {
            _activeRecordAccount = value;
        }
    }
}