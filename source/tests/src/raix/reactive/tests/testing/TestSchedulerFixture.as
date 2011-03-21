package raix.reactive.tests.testing
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class TestSchedulerFixture
	{
		[Test]
		public function immediate_actions_are_not_called_immediately() : void
		{
			var wasCalled : Boolean = false;
			var action : Function = function():void { wasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			scheduler.schedule(action);			
			
			Assert.assertFalse(wasCalled);
		}
		
		[Test]
		public function actions_can_be_scheduled_then_run() : void
		{
			var wasCalled : Boolean = false;
			var action : Function = function():void { wasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			
			scheduler.schedule(action);			
			scheduler.run(); 
			
			Assert.assertTrue(wasCalled);
		}
		
		[Test]
		public function immediate_actions_will_be_executed_at_the_same() : void
		{
			var aWasCalled : Boolean = false;
			var bWasCalled : Boolean = false;
			var actionA : Function = function():void { aWasCalled = true; }
			var actionB : Function = function():void { bWasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			
			scheduler.schedule(actionA);
			scheduler.schedule(actionB);
			scheduler.runTo(1); 
			
			Assert.assertTrue(aWasCalled);
			Assert.assertTrue(bWasCalled);
		}
		
		[Test]
		public function actions_with_the_same_due_time_are_called_at_the_same_time() : void
		{
			var aWasCalled : Boolean = false;
			var bWasCalled : Boolean = false;
			var actionA : Function = function():void { aWasCalled = true; }
			var actionB : Function = function():void { bWasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			
			scheduler.schedule(actionA, 10);
			scheduler.schedule(actionB, 10);
			
			scheduler.runTo(10);			
			Assert.assertTrue(aWasCalled);
			Assert.assertTrue(bWasCalled);
		}
		
		[Test]
		public function actions_with_the_same_due_time_are_called_in_scheduled_order() : void
		{
			var aWasCalled : Boolean = false;
			var bWasCalled : Boolean = false;
			var actionA : Function = function():void { aWasCalled = true; }
			var actionB : Function = function():void { Assert.assertTrue(aWasCalled); bWasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			
			scheduler.schedule(actionA, 10);
			scheduler.schedule(actionB, 10);
			
			scheduler.runTo(10);			
			Assert.assertTrue(aWasCalled);
			Assert.assertTrue(bWasCalled);
		}
		
		[Test]
		public function immediate_actions_are_called_before_future_actions() : void
		{
			var aWasCalled : Boolean = false;
			var bWasCalled : Boolean = false;
			var cWasCalled : Boolean = false;
			var actionA : Function = function():void { aWasCalled = true; }
			var actionB : Function = function():void { bWasCalled = true; }
			var actionC : Function = function():void { cWasCalled = true; }
			
			var scheduler : TestScheduler = new TestScheduler();
			
			scheduler.schedule(actionA, 10);
			
			scheduler.runTo(10);
			Assert.assertTrue(aWasCalled);
			Assert.assertFalse(bWasCalled);
			Assert.assertFalse(cWasCalled);
			
			scheduler.schedule(actionB, 10);
			scheduler.schedule(actionC, 0);
			
			scheduler.runTo(11);
			Assert.assertTrue(cWasCalled);
			Assert.assertFalse(bWasCalled);
			
			scheduler.runTo(12);
			Assert.assertFalse(bWasCalled);
			
			scheduler.runTo(20);
			Assert.assertTrue(bWasCalled);
		}
		
		[Test]
		public function actions_will_be_run_in_time_order() : void
		{
			var output : Array = new Array();
			
			var actions : Array = Enumerable.range(0, 5)
				.map(function(i:int):Function
				{
					return function() : void
					{
						output.push(i);
					};
				}).toArray();
			
			var scheduler : TestScheduler = new TestScheduler();
			
			var testSchedule : int = 10;
			
			//for each(var action : Function in actions)
			for (var i:int=0;i<actions.length; i++)
			{
				var action : Function = actions[i];
				var dueTime : int = (actions.length - i) * testSchedule;
				
				scheduler.schedule(action, dueTime);
			}

			scheduler.run(); 
			
			AssertEx.assertArrayEquals(output, [4, 3, 2, 1, 0]);
		}
	}
}