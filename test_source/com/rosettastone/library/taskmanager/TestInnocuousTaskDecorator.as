package com.rosettastone.library.taskmanager {
	
	public class TestInnocuousTaskDecorator extends AbstractTaskTestCase {
		
		private var _stubTask:StubTask;
		private var _innocuousTaskDecorator:InnocuousTaskDecorator;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_stubTask = new StubTask();
			
			_innocuousTaskDecorator =
				new InnocuousTaskDecorator( _stubTask );
			
			addTaskEventListeners( _innocuousTaskDecorator );
		}
		
		[After]
		override public function tearDown():void {
		}
		
		[Test]
		public function testDecoratedTaskCompletes():void {
			_innocuousTaskDecorator.run();
			
			_stubTask.complete();
			
			assertFalse( _innocuousTaskDecorator.running );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testDecoratedTaskFails():void {
			_innocuousTaskDecorator.run();
			
			_stubTask.error( "Fail" );
			
			assertFalse( _innocuousTaskDecorator.running );
			
			assertNumEvents( 1, 0, 0 );
		}
	}
}