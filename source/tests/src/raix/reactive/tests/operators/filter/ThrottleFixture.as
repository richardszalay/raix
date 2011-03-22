package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.OnNext;
	import raix.reactive.testing.ColdObservable;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class ThrottleFixture
	{
		private var scheduler : TestScheduler;
		private var observer : StatsObserver;
		private var source : ColdObservable;
		
		[Before]
		public function setUp() : void
		{
			scheduler = new TestScheduler();
			
			observer = new StatsObserver();
			 
			source = scheduler.createColdObservable([
				new Recorded(10, new OnNext(1)),
				new Recorded(15, new OnNext(2)),
				new Recorded(20, new OnNext(3)),
				new Recorded(35, new OnNext(4)),
				new Recorded(40, new OnNext(5))
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
			
			Assert.assertEquals(0, observer.nextValues.length);
		}
		
		[Test]
		public function value_is_released_after_no_values_received_in_duration() : void
		{
			scheduler.runTo(25);
			
			Assert.assertEquals(1, observer.nextValues.length);
			Assert.assertEquals(3, observer.nextValues[0]);
		}
		
		[Test]
		public function last_value_before_duration_is_emitted() : void
		{
			scheduler.runTo(25);
			
			Assert.assertEquals(3, observer.nextValues[0]);
		}
		
		[Test]
		public function timeout_is_reset_after_next_value_is_received() : void
		{
			scheduler.runTo(45);
			
			Assert.assertEquals(2, observer.nextValues.length);
			Assert.assertEquals(5, observer.nextValues[1]);
		}
	}
}