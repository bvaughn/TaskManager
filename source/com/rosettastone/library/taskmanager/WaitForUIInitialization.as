package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.InterruptibleTask;
	import com.rosettastone.library.taskmanager.Task;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	/**
	 * Convenience task for waiting until a specified UIComponent has initialized.
	 * This can be useful if app initialization (business logic) also depends on UI initialization.
	 */
	public class WaitForUIInitialization extends InterruptibleTask {
		
		private var _uiComponent:UIComponent;
		
		/**
		 * Constructor.
		 * 
		 * @param uiComponent Component to wait for initialization from
		 */
		public function WaitForUIInitialization( uiComponent:UIComponent, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_uiComponent = uiComponent;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( _uiComponent.initialized || _uiComponent.parent != null ) {
				taskComplete();
			} else {
				_uiComponent.addEventListener( FlexEvent.INITIALIZE, onInitialize );
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			_uiComponent.removeEventListener( FlexEvent.INITIALIZE, onInitialize );
		}
		
		/*
		 * Event handlers
		 */
		
		private function onInitialize( event:FlexEvent ):void {
			_uiComponent.removeEventListener( FlexEvent.CREATION_COMPLETE, onInitialize );
			
			taskComplete();
		}
	}
}