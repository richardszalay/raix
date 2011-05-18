package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.OnCompleted;
	import raix.reactive.OnNext;
	import raix.reactive.testing.ColdObservable;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	
	[TestCase]
	public class ThrottleFixture
	{
		private var scheduler : TestScheduler;
		private var observer : MockObserver;
		private var source : ColdObservable;
		
		[Before]
		public function setUp() : void
		{
			scheduler = new TestScheduler();
			
			observer = new MockObserver(scheduler);
			 
			source = scheduler.createColdObservable([
				new Recorded(10, new OnNext(1)),
				new Recorded(15, new OnNext(2)),
				new Recorded(20, new OnNext(3)),
				new Recorded(35, new OnNext(4)),
				new Recorded(40, new OnNext(5)),
				new Recorded(46, new OnNext(6)),
				new Recorded(47, new OnCompleted())
			]);
			;
			
			source
				.throttle(5, scheduler)
				.subscribeWith(observer);
		}
		
		[Test]
		public function immediately_subscribes_to_source() : void
		{
			Assert.assertTrue(source.subscriptions.length);
		}
		
		[Test]
		public function values_are_not_released_when_emitted() : void
		{
			scheduler.runTo(10);
			
			Assert.assertEquals(0, observer.recordedNotifications.length);
		}
		
		[Test]
		public function value_is_released_after_no_values_received_in_duration() : void
		{
			scheduler.runTo(25);
			
			observer.assertTimings([
				new Recorded(25, new OnNext(3))
			], Assert.fail);
		}
		
		[Test]
		public function timeout_is_reset_after_next_value_is_received() : void
		{
			scheduler.runTo(45);
			
			observer.assertTimings([
				new Recorded(25, new OnNext(3)),
				new Recorded(45, new OnNext(5))
			], Assert.fail);
		}
		
		[Test]
		public function last_value_is_emitted_when_source_completes() : void
		{
			scheduler.run();
			
			observer.assertTimings([
				new Recorded(25, new OnNext(3)),
				new Recorded(45, new OnNext(5)),
				new Recorded(47, new OnNext(6)),
				new Recorded(47, new OnCompleted()),
			], Assert.fail);
		}
	}
}