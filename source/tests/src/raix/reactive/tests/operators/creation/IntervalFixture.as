package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnNext;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler; 
	
	[RunWith("asmock.integration.flexunit.ASMockClassRunner")]
	public class IntervalFixture
	{
		[Mock] public static var schedulerMock : IScheduler;
		
		public function IntervalFixture()
		{
		}
		
		[Test]
		public function emits_values_at_interval() : void
		{
			var scheduler : TestScheduler =new TestScheduler();
			
			var observer : MockObserver = new MockObserver(scheduler);
			
			Observable.interval(10, scheduler)
				.take(5)
				.subscribeWith(observer);
				
			scheduler.run();
				
			observer.assertTimings([
				new Recorded(10, new OnNext(0)),
				new Recorded(20, new OnNext(1)),
				new Recorded(30, new OnNext(2)),
				new Recorded(40, new OnNext(3)),
				new Recorded(50, new OnNext(4)),
				new Recorded(50, new OnCompleted())
			], Assert.fail);
		}
		
		[Test]
		public function unsubscribing_cancels() : void
		{
			var scheduler : TestScheduler =new TestScheduler();
			
			var observer : MockObserver = new MockObserver(scheduler);
			
			var subscription : ICancelable = Observable.interval(10, scheduler)
				.subscribeWith(observer);
				
			scheduler.runTo(40);
			
			subscription.cancel();
			
			scheduler.runTo(100);
			
			Assert.assertEquals(4, observer.recordedNotifications.length);
			Assert.assertEquals(0, scheduler.actionCount);
		}
	}
}