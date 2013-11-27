package com.rosettastone.library.taskmanager {
	
	use namespace TaskPrivateNamespace;
	
	public class TestFactoryTask extends AbstractTaskTestCase {
		
		[Before]
		override public function setUp():void {
			super.setUp();
		}
		
		[After]
		override public function tearDown():void {
		}
		
		[Test]
		public function testBasicOperation():void {
			var stubTask:StubTask;
			var factoryFunction:Function =
				function():ITask {
					stubTask = new StubTask();
					
					return stubTask;
				};
			
			var factoryTask:FactoryTask =
				new FactoryTask( factoryFunction );
			
			addTaskEventListeners( factoryTask );
			
			assertNull( stubTask );
			
			factoryTask.run();
			
			assertNotNull( stubTask );
			assertTrue( factoryTask.running );
			assertTrue( stubTask.running );
			
			stubTask.complete();
			
			assertFalse( stubTask.running );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testScopeWithThisOperatorAndOptionalMethodParameters():void {
			var object:Object = new Object();
			var assertValue:Boolean;
			
			var factoryFunction:Function =
				function( reference:* ):Task {
					assertValue = this == reference;
					
					return new StubTask( true );
				};
			
			new FactoryTask( factoryFunction, object, [ object ] ).run();
			
			assertTrue( assertValue );
		}
		
		[Test]
		public function testScopeWithoutThisOperator():void {
			var assertValue:Boolean;
			
			var factoryFunction:Function =
				function():ITask {
					assertValue = this is FactoryTask;
					
					return new StubTask( true );
				};
			
			new FactoryTask( factoryFunction ).run();
			
			assertTrue( assertValue );
		}
		
		/*
		 * Interruptible behavior
		 */
		
		[Test]
		public function testTaskNotYetCreatedNonInterruptibleTaskWrappedWithInterruptibleDecorator():void {
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						return new StubTask();
					} );
			factoryTask.run();
			
			assertTrue( factoryTask.decoratedTask is IInterruptibleTask );
			assertTrue( factoryTask.decoratedTask is InterruptibleDecoratorTask );
			assertTrue( ( factoryTask.decoratedTask as InterruptibleDecoratorTask ).decoratedTask is StubTask );
		}
		
		[Test]
		public function testTaskNotYetCreatedTaskWillBeInterruptibleParam():void {
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						return new StubTask();
					}, this, null, true );
			
			assertTrue( factoryTask.interruptible );
		}
		
		[Test]
		public function testInterruptibleGetter():void {
			var stubTask:StubTask;
			
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						stubTask = new StubTask();
						
						return stubTask;
					} );
			
			assertNull( stubTask );
			
			factoryTask.run();
			
			assertNotNull( stubTask );
			assertFalse( stubTask.interruptible );
			assertTrue( factoryTask.interruptible );
		}
		
		[Test]
		public function testInterruptibleBehaviorGetsPassedThroughToInnerTask():void {
			var stubTask:InterruptibleStubTask;
			
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						stubTask = new InterruptibleStubTask();
						
						return stubTask;
					} );
			factoryTask.run();
			
			assertTrue( factoryTask.interruptible, stubTask.interruptible );
			
			factoryTask.interrupt();
			
			assertTrue( factoryTask.isInterrupted, stubTask.isInterrupted );
			assertFalse( factoryTask.running, stubTask.running );
			
			var originalStubTask:InterruptibleStubTask = stubTask;
			
			factoryTask.run();
			
			assertTrue( factoryTask.running, stubTask.running );
			assertTrue( originalStubTask === stubTask );
		}
		
		[Test]
		public function test_reset_clearsDecoratedTaskReference():void {
			var stubTasks:Array = new Array();
			
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						var stubTask:ITask = new InterruptibleStubTask();
						
						stubTasks.push( stubTask );
						
						return stubTask;
					} );
			factoryTask.run();
			
			assertEquals( 1, stubTasks.length );
			assertStrictlyEquals( stubTasks[0], factoryTask.decoratedTask );
			
			( stubTasks[0] as InterruptibleStubTask ).doTaskComplete();
			
			factoryTask.reset(); // Reset doens't work if Task is running
			
			assertNull( factoryTask.decoratedTask );
			
			factoryTask.run();
			
			assertEquals( 2, stubTasks.length );
			assertStrictlyEquals( stubTasks[1], factoryTask.decoratedTask );
		}
		
		// Test resume after error
		
		[Test]
		public function test_reexecuteFactoryFunctionAfterError_true():void {
			var stubTasks:Array = new Array();
			
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						var stubTask:ITask = new InterruptibleStubTask();
						
						stubTasks.push( stubTask );
						
						return stubTask;
					} );
			factoryTask.setReexecuteFactoryFunctionAfterError( true );
			factoryTask.run();
			
			assertEquals( 1, stubTasks.length );
			assertStrictlyEquals( stubTasks[0], factoryTask.decoratedTask );
			
			( stubTasks[0] as InterruptibleStubTask ).doTaskError();
			
			factoryTask.run();
			
			assertEquals( 2, stubTasks.length );
			assertStrictlyEquals( stubTasks[1], factoryTask.decoratedTask );
		}
		
		[Test]
		public function test_reexecuteFactoryFunctionAfterError_false():void {
			var stubTasks:Array = new Array();
			
			var factoryTask:FactoryTask =
				new FactoryTask(
					function():ITask {
						var stubTask:ITask = new InterruptibleStubTask();
						
						stubTasks.push( stubTask );
						
						return stubTask;
					} );
			factoryTask.setReexecuteFactoryFunctionAfterError( false );
			factoryTask.run();
			
			assertEquals( 1, stubTasks.length );
			assertStrictlyEquals( stubTasks[0], factoryTask.decoratedTask );
			
			( stubTasks[0] as InterruptibleStubTask ).doTaskError();
			
			factoryTask.run();
			
			assertEquals( 1, stubTasks.length );
			assertStrictlyEquals( stubTasks[0], factoryTask.decoratedTask );
		}
	}
}