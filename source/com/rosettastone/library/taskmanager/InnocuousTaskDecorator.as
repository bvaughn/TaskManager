package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	/**
	 * Decorates a Task but re-dispatches both error and success events as success.
	 * This type of decorator should be used for Tasks that are required and are blocking, but should not be considered fatal in the event of a failure.
	 */
	public class InnocuousTaskDecorator extends InterruptibleTask implements IDecoratorTask {
		
		private var _decorated:ITask;
		
		public function InnocuousTaskDecorator( decorated:ITask, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_decorated = decorated;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get decoratedTask():ITask {
			return _decorated;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get isComplete():Boolean {
			return _decorated.isComplete
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get running():Boolean {
			return _decorated.running;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			_decorated.addEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decorated.addEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			_decorated.addEventListener( TaskEvent.INTERRUPTED, onDecoratedTaskInterrupted );
			_decorated.run();
			
			// Don't re-dispatch TaskEvent.STARTED events because super.run() does this automatically.
			// It's a final function so we can't override it.
		}
		
		/**
		 * @inheritDoc
		 */
		override public function interrupt():Boolean {
			if ( _decorated is IInterruptibleTask ) {
				return ( _decorated as IInterruptibleTask ).interrupt();
			}
			
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function reset():void {
			_decorated.reset();
		}
		
		/*
		 * Event handlers
		 */
		
		private function onDecoratedTaskComplete( event:TaskEvent ):void {
			dispatchEvent( event );
		}
		
		private function onDecoratedTaskError( event:TaskEvent ):void {
			dispatchEvent( new TaskEvent( TaskEvent.COMPLETE ) );
		}
		
		private function onDecoratedTaskInterrupted( event:TaskEvent ):void {
			dispatchEvent( event );
		}
	}
}