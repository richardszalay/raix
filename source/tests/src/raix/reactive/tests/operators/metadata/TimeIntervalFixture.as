package raix.reactive.tests.operators.metadata
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class TimeIntervalFixture
	{
		[Test(async)]
		public function value_is_wrapped_in_time_interval() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			Observable.range(0, 2, scheduler)
				.timeInterval()
				.subscribeWith(stats);
				
			scheduler.runNext();

			Async.asyncHandler(this, function():void {}, 100, null, function():void
			{
				scheduler.runNext();
				
				var firstInterval : Number = stats.nextValues[0].interval;
				var lastInterval : Number = stats.nextValues[stats.nextCount - 1].interval;
				
				Assert.assertEquals(0, firstInterval);
				
				// Flash runtime timers arent always exact so we can't assume >= 100
				Assert.assertTrue(lastInterval > 50);
			});
		}
	}
}