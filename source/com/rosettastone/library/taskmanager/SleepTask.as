package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.InterruptibleTask;
	
	/**
	 * Sleeps until told to complete.
	 * This Task can be inserted into a composite to block for an indeterminate amount of time.
	 * Since this Task is simple a placeholder, it supports interruptibility.
	 */
	public class SleepTask extends InterruptibleTask {
		
		/**
		 * Constructor.
		 * 
		 * @param taskIdentifier Human-friendly Task identifier
		 */
		public function SleepTask( taskIdentifier:String = null ) {
			super( taskIdentifier );
		}
		
		/**
		 * Stop sleeping and complete Task.
		 */
		public function complete():void {
			taskComplete();
		}
		
		/*
		 * Task overrides
		 */
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			// No-op
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			// No-op
		}
	}
}