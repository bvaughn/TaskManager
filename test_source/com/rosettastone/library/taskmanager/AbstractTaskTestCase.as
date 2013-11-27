package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	import flexunit.framework.BetterTestCase;
	
	public class AbstractTaskTestCase extends BetterTestCase {
		
		protected var _data:*;
		protected var _message:String;
		protected var _numCompleteEvents:int;
		protected var _numErrorEvents:int;
		protected var _numFinalEvents:int;
		protected var _numInterruptedEvents:int;
		protected var _numStartedEvents:int;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_numCompleteEvents = 0;
			_numErrorEvents = 0;
			_numFinalEvents = 0;
			_numInterruptedEvents = 0;
		}
		
		/*
		 * Helper methods
		 */
		
		protected function assertNumEvents( numComplete:int, numError:int, numInterrupted:int ):void {
			assertEquals( numComplete, _numCompleteEvents );
			assertEquals( numError, _numErrorEvents );
			assertEquals( numInterrupted, _numInterruptedEvents );
		}
		
		protected function addAsyncTaskEventListeners( task:ITask, timeout:int = 1000 ):void {
			task.addEventListener( TaskEvent.COMPLETE, addAsync( onTaskComplete, timeout ), false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.ERROR, addAsync( onTaskError, timeout ), false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.INTERRUPTED, addAsync( onTaskInterrupted, timeout ), false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.STARTED, addAsync( onTaskStarted, timeout ), false, int.MAX_VALUE );
		}
		
		protected function addTaskEventListeners( task:ITask ):void {
			task.addEventListener( TaskEvent.COMPLETE, onTaskComplete, false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.ERROR, onTaskError, false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.FINAL, onTaskFinal, false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.INTERRUPTED, onTaskInterrupted, false, int.MAX_VALUE );
			task.addEventListener( TaskEvent.STARTED, onTaskStarted, false, int.MAX_VALUE );
		}
		
		protected function addTaskHandlers( task:ITask ):void {
			task.withCompleteHandler( completeHandler );
			task.withErrorHandler( errorHandler );
			task.withFinalHandler( finalHandler );
			task.withStartedHandler( startedHandler );
		}
		
		protected function resetNumEvents():void {
			_numCompleteEvents = 0;
			_numErrorEvents = 0;
			_numInterruptedEvents = 0;
		}
		
		/*
		 * Complete / success handlers
		 */
		
		protected function completeHandler( message:String = "", data:* = null ):void {
			_data = data;
			_message = message;
			
			_numCompleteEvents++;
		}
		
		protected function errorHandler( message:String, data:* = null ):void {
			_data = data;
			_message = message;
			
			_numErrorEvents++;
		}
		
		protected function finalHandler():void {
			_numFinalEvents++;
		}
		
		protected function interruptionHandler( message:String = "", data:* = null ):void {
			_data = data;
			_message = message;
			
			_numInterruptedEvents++;
		}
		
		protected function startedHandler():void {
			_numStartedEvents++;
		}
		
		/*
		 * Event handlers
		 */
		
		protected function onTaskComplete( event:TaskEvent ):void {
			_data = event.data;
			_message = event.message;
			
			_numCompleteEvents++;
		}
		
		protected function onTaskError( event:TaskEvent ):void {
			_data = event.data;
			_message = event.message;
			
			_numErrorEvents++;
		}
		
		protected function onTaskFinal( event:TaskEvent ):void {
			_numFinalEvents++;
		}
		
		protected function onTaskInterrupted( event:TaskEvent ):void {
			_data = event.data;
			_message = event.message;
			
			_numInterruptedEvents++;
		}
		
		protected function onTaskStarted( event:TaskEvent ):void {
			_numStartedEvents++;
		}
	}
}