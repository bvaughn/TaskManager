package unittests {
	import com.rosettastone.library.taskmanager.TestCompositeTask;
	import com.rosettastone.library.taskmanager.TestEventHandlingTask;
	import com.rosettastone.library.taskmanager.TestFactoryTask;
	import com.rosettastone.library.taskmanager.TestInnocuousTaskDecorator;
	import com.rosettastone.library.taskmanager.TestInterruptibleCompositeTask;
	import com.rosettastone.library.taskmanager.TestObserverTask;
	import com.rosettastone.library.taskmanager.TestPlaySoundTask;
	import com.rosettastone.library.taskmanager.TestRetryOnFailureDecoratorTask;
	import com.rosettastone.library.taskmanager.TestTask;
	import com.rosettastone.library.taskmanager.TestTaskManager;
	import com.rosettastone.library.taskmanager.TestTaskWithClosure;
	import com.rosettastone.library.taskmanager.TestTaskWithTimeout;
	import com.rosettastone.library.taskmanager.TestURLRequestTask;
	import com.rosettastone.library.taskmanager.TestWaitForUIInitialization;
	import com.rosettastone.library.taskmanager.TestWaitTask;
	
	/**
	 * A simple holder class for flexunit TestCase objects that are run by TaskManagerUnitTestRunner.
	 * 
	 * @see TaskManagerUnitTestRunner
	 * @see unittests.suites
	 */
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class TaskManagerTestSuite extends TestSuiteBase {
		
		public var t1:TestTaskManager;
		public var t2:TestTask;
		public var t3:TestWaitTask;
		public var t4:TestCompositeTask;
		public var t5:TestInterruptibleCompositeTask;
		public var t6:TestPlaySoundTask;
		public var t7:TestInnocuousTaskDecorator;
		public var t8:TestTaskWithClosure;
		public var t9:TestTaskWithTimeout;
		public var t10:TestFactoryTask;
		public var t11:TestEventHandlingTask;
		public var t12:TestObserverTask;
		public var t13:TestWaitForUIInitialization;
		public var t14:TestURLRequestTask;
		public var t15:TestRetryOnFailureDecoratorTask;
	}
}
