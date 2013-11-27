package com.rosettastone.library.taskmanager {
	
	/**
	 * Synchronous Task for convenience sub-class purposes.
	 */
	public class SynchronousTask extends Task implements ISynchronousTask, IInterruptibleTask {
		
		public function SynchronousTask( taskIdentifier:String = null ) {
			super( taskIdentifier );
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get synchronous():Boolean {
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		override final protected function customRun():void {
			try {
				customRunHook();
				
				taskComplete();
				
			} catch ( error:Error ) {
				taskError( error.message, error );
			}
		}
		
		/**
		 * Synchronous run method.
		 * Sub-classes must override this method.
		 */
		protected function customRunHook():void {
			throw Error( "customRunHook() must be implemented" );
		}
	}
}