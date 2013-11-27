package com.rosettastone.library.taskmanager {
	import flash.display.DisplayObjectContainer;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	public class TestWaitForUIInitialization extends AbstractTaskTestCase {
		
		private var _task:WaitForUIInitialization;
		private var _uiComponent:UIComponent;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_uiComponent = new UIComponent();
			
			_task = new WaitForUIInitialization( _uiComponent );
		}
		
		protected function addUIComponentAsChildToApplication():void {
			try {
				FlexGlobals.topLevelApplication.addChild( _uiComponent );
			} catch ( error:Error ) {
				FlexGlobals.topLevelApplication.addElement( _uiComponent );
			}
		}
		
		[Test]
		public function testUIComponentInitializedBeforeTaskCreated():void {
			addUIComponentAsChildToApplication()
			
			assertTrue( _uiComponent.parent != null );
			
			_task = new WaitForUIInitialization( _uiComponent );
			
			addTaskEventListeners( _task );
			
			_task.run();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testUIComponentInitializedAfterTaskCreatedButBeforeTaskRun():void {
			addTaskEventListeners( _task );
			
			addUIComponentAsChildToApplication();
			
			assertTrue( _uiComponent.parent != null );
			
			assertNumEvents( 0, 0, 0 );
			
			_task.run();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testUIComponentInitializedAfterTaskRun():void {
			addTaskEventListeners( _task );
			
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			addUIComponentAsChildToApplication();
			
			assertTrue( _uiComponent.parent != null );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testUIComponentInitializedWhileTaskPaused():void {
			addTaskEventListeners( _task );
			
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.interrupt();
			
			assertNumEvents( 0, 0, 1 );
			
			addUIComponentAsChildToApplication();
			
			assertTrue( _uiComponent.parent != null );
			
			assertNumEvents( 0, 0, 1 );
			
			_task.run();
			
			assertNumEvents( 1, 0, 1 );
		}
	}
}