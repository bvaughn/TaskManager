package com.rosettastone.library.taskmanager {
	
	use namespace TaskPrivateNamespace;
	
	/**
	 * Abstract inerruptible Task.
	 * Extend this class and override the customInterrupt() method to support interruptibility.
	 */
	public class InterruptibleTask extends Task implements IInterruptibleTask {
		
		/**
		 * Constructor.
		 */
		public function InterruptibleTask( taskIdentifier:String = null ) {
			super( taskIdentifier );
		}
		
		/**
		 * @inheritDoc
		 */
		override public function interrupt():Boolean {
			if ( running ) {
				customInterrupt();
				
				taskInterrupted();
				
				return true;
			}
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get interruptible():Boolean {
			return true;
		}
		
		/*
		 * Sub-class hook methods
		 */
		
		/**
		 * Sub-classes should override this method to implement interruption behavior (removing event listeners, pausing objects, etc.).
		 */
		protected function customInterrupt():void {
			throw Error( "Interruptions must be handled" );
		}
	}
}