package raix.reactive.tests.operators.creation
{
	import asmock.framework.Expect;
	import asmock.framework.MockRepository;
	import asmock.framework.constraints.Is;
	
	import org.flexunit.Assert;
	
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.OnNext;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.NullScheduledAction;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class TimerFixture
	{
		[Test]
		public function uses_delayMs_for_first_schedule_and_intervalMs_afterwards() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var delayValue : int = 25;
			var intervalValue : int = 50;
			
			Observable.timer(delayValue, intervalValue, scheduler)
				.take(3)
				.subscribeWith(observer);
			
			scheduler.run();
			
			observer.assertTimings([
				new Recorded(25, new OnNext(0)),
				new Recorded(75, new OnNext(1)),
				new Recorded(125, new OnNext(2)),
				], Assert.fail);
		}
		
		[Test]
		public function does_not_fire_onnext_until_scheduler_returns() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var intervalValue : int = 50;
			
			Observable.timer(intervalValue, intervalValue, scheduler)
				.subscribeWith(observer);
			
			Assert.assertEquals(0, observer.recordedNotifications.length);
			
			scheduler.runTo(50);
			Assert.assertEquals(1, observer.recordedNotifications.length);
		}
		
		[Test]
		public function unsubscribing_cancels_scheduled_action() : void
		{
			var intervalValue : int = 50;
			
			var returnScheduledAction : ICancelable = Cancelable.empty;
			
			var scheduler : ManualScheduler = new ManualScheduler();
		
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = 
				Observable.timer(intervalValue, intervalValue, scheduler).subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertEquals(1, scheduler.queueSize);
			
			subscription.cancel();
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertEquals(0, scheduler.queueSize);
		}
		
		[Test]
		public function unsubscribing_cancels_scheduled_action_after_first_iteration() : void
		{
			var intervalValue : int = 50;
			
			var returnScheduledAction : ICancelable = Cancelable.empty;
			
			var scheduler : ManualScheduler = new ManualScheduler();
		
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = 
				Observable.timer(intervalValue, intervalValue, scheduler).subscribeWith(stats);
			
			scheduler.runNext();
			
			Assert.assertTrue(stats.nextCalled);
			Assert.assertEquals(1, scheduler.queueSize);
			
			subscription.cancel();
			
			Assert.assertTrue(stats.nextCalled);
			Assert.assertEquals(0, scheduler.queueSize);
		}
	}
}