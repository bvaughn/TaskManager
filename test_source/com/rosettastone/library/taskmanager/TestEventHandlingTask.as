package com.rosettastone.library.taskmanager {
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class TestEventHandlingTask extends AbstractTaskTestCase {
		
		private var _eventDispatcher:IEventDispatcher;
		private var _eventHandlingTask:EventHandlingTask;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_eventDispatcher = new EventDispatcher();
			_eventHandlingTask = new EventHandlingTask( _eventDispatcher, Event.COMPLETE, ErrorEvent.ERROR );
			
			addTaskEventListeners( _eventHandlingTask );
		}
		
		[After]
		override public function tearDown():void {
		}
		
		[Test]
		public function testCompleteEventHandled():void {
			_eventHandlingTask.run();
			
			var event:Event = new Event( Event.COMPLETE );
			
			_eventDispatcher.dispatchEvent( event );
			
			assertNumEvents( 1, 0, 0 );
			assertStrictlyEquals( event, _eventHandlingTask.data );
		}
		
		[Test]
		public function testFailureEventHandled():void {
			_eventHandlingTask.run();
			
			var event:Event = new Event( ErrorEvent.ERROR );
			
			_eventDispatcher.dispatchEvent( event );
			
			assertNumEvents( 0, 1, 0 );
			assertStrictlyEquals( event, _eventHandlingTask.data );
		}
		
		[Test]
		public function testFailureEventIgnoredIfNotSpecified():void {
			_eventHandlingTask = new EventHandlingTask( _eventDispatcher, Event.COMPLETE );
			
			addTaskEventListeners( _eventHandlingTask );
			
			_eventHandlingTask.run();
			
			_eventDispatcher.addEventListener(
				ErrorEvent.ERROR,
				function( event:ErrorEvent ):void {
					// We must listen for an ErrorEvent somewhere or Flash will complain:
					// Error #2044: Unhandled error:. text=
				} );
			
			_eventDispatcher.dispatchEvent( new ErrorEvent( ErrorEvent.ERROR ) );
			
			assertNumEvents( 0, 0, 0 );
			
			_eventDispatcher.dispatchEvent( new Event( Event.COMPLETE ) );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testNoEventListenersAreAddedUntilTaskIsRun():void {
			_eventDispatcher.dispatchEvent( new Event( Event.COMPLETE ) );
			
			assertNumEvents( 0, 0, 0 );
			
			_eventHandlingTask.run();
			
			_eventDispatcher.dispatchEvent( new Event( Event.COMPLETE ) );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		// Interruption tests
		
		[Test]
		public function testInterruptAndResume():void {
			_eventHandlingTask.run();
			
			assertTrue( _eventHandlingTask.running );
			
			_eventHandlingTask.interrupt();
			
			assertFalse( _eventHandlingTask.running );
			
			_eventHandlingTask.run();
			
			assertTrue( _eventHandlingTask.running );
		}
		
		[Test]
		public function testCompleteEventDispatchedWhileInterrupted():void {
			_eventHandlingTask.run();
			_eventHandlingTask.interrupt();
			
			_eventDispatcher.dispatchEvent( new Event( Event.COMPLETE ) );
			
			assertEquals( 0, _eventHandlingTask.numTimesCompleted );
			
			_eventHandlingTask.run();
			
			assertTrue( _eventHandlingTask.isComplete );
			assertEquals( 1, _eventHandlingTask.numTimesCompleted );
		}
		
		[Test]
		public function testErrorEventDispatchedWhileInterrupted():void {
			_eventHandlingTask.run();
			_eventHandlingTask.interrupt();
			
			_eventDispatcher.dispatchEvent( new ErrorEvent( ErrorEvent.ERROR ) );
			
			assertEquals( 0, _eventHandlingTask.numTimesCompleted );
			
			_eventHandlingTask.run();
			
			assertTrue( _eventHandlingTask.isErrored );
			assertEquals( 1, _eventHandlingTask.numTimesErrored );
		}
		
		// Multiple event types
		
		[Test]
		public function testMultipleCompleteEvents():void {
			var eventTypes:Array = [ Event.COMPLETE, Event.SELECT ];
			
			for each ( var eventType:String in eventTypes ) {
				_eventHandlingTask = new EventHandlingTask( _eventDispatcher, eventTypes, ErrorEvent.ERROR );
				
				addTaskEventListeners( _eventHandlingTask );
				
				_eventHandlingTask.run();
				
				_eventDispatcher.dispatchEvent( new Event( eventType ) );
				
				assertNumEvents( 1, 0, 0 );
				resetNumEvents();
			}
		}
		
		[Test]
		public function testMultipleErrorEvents():void {
			var eventTypes:Array = [ "foo", "bar" ];
			
			for each ( var eventType:String in eventTypes ) {
				_eventHandlingTask = new EventHandlingTask( _eventDispatcher, Event.COMPLETE, eventTypes );
				
				addTaskEventListeners( _eventHandlingTask );
				
				_eventHandlingTask.run();
				
				_eventDispatcher.dispatchEvent( new Event( eventType ) );
				
				assertNumEvents( 0, 1, 0 );
				resetNumEvents();
			}
		}
	}
}