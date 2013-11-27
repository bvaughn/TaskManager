package com.rosettastone.library.taskmanager {
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	/**
	 * Convenience Task that listens to an IEventDispatcher for either a success or failure type event.
	 * 
	 * This Task can be used within a composite to block on the dispatching of an event.
	 * It saves users from creating custom Tasks just to handle event listening.
	 * 
	 * This task can be interrupted, though interrupting it will not stop (or affect) the IEventDispatcher it monitors.
	 * Events dispatched while this task is in an interrupted state will be queued and handled when the task is resumed.
	 * 
	 * If multiple Events are dispatched, only the first one will be responded-to / observed.
	 * 
	 * Upon completion of this Task the Event that triggered the completion will be accessible via the "data" propery.
	 */
	public class EventHandlingTask extends InterruptibleTask {
		
		private var _eventDispatcher:IEventDispatcher;
		private var _failureEventTypes:Array;
		private var _pendingEvent:Event;
		private var _successEventTypes:Array;
		
		/**
		 * Constructor.
		 * 
		 * @param eventDispatcher Event dispatcher object
		 * @param successEventTypeOrTypes One or more event types indicating success (String or Array)
		 * @param failureEventTypeOrTypes One or more event types indicating failure (String or Array)
		 */
		public function EventHandlingTask( eventDispatcher:IEventDispatcher,
		                                   successEventTypeOrTypes:*,
										   failureEventTypeOrTypes:* = null,
										   taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_eventDispatcher = eventDispatcher;
			_successEventTypes = successEventTypeOrTypes is Array ? successEventTypeOrTypes : new Array( successEventTypeOrTypes );
			
			if ( failureEventTypeOrTypes ) {
				_failureEventTypes = failureEventTypeOrTypes is Array ? failureEventTypeOrTypes : new Array( failureEventTypeOrTypes );
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			// No-op
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( _pendingEvent ) {
				handleEvent( _pendingEvent );
				
			} else {
				for each ( var successEventType:String in _successEventTypes ) {
					_eventDispatcher.addEventListener( successEventType, onSuccessOrFailure );
				}
				
				if ( _failureEventTypes ) {
					for each ( var failureEventType:String in _failureEventTypes ) {
						_eventDispatcher.addEventListener( failureEventType, onSuccessOrFailure );
					}
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			_pendingEvent = null;
		}
		
		/*
		 * Helper methods
		 */
		
		private function handleEvent( event:Event ):void {
			if ( _successEventTypes.indexOf( event.type ) >= 0 ) {
				taskComplete( "", event );
			} else if ( _failureEventTypes.indexOf( event.type ) >= 0 ) {
				taskError( "Task failed", event );
			}
			
			_pendingEvent = null;
		}
		
		private function removeEventListeners():void {
			for each ( var successEventType:String in _successEventTypes ) {
				_eventDispatcher.removeEventListener( successEventType, onSuccessOrFailure );
			}
			
			if ( _failureEventTypes ) {
				for each ( var failureEventType:String in _failureEventTypes ) {
					_eventDispatcher.removeEventListener( failureEventType, onSuccessOrFailure );
				}
			}
		}
		
		/*
		 * Event handler
		 */
		
		private function onSuccessOrFailure( event:Event ):void {
			removeEventListeners();
			
			if ( running ) {
				handleEvent( event );
			} else {
				_pendingEvent = event;
			}
		}
	}
}