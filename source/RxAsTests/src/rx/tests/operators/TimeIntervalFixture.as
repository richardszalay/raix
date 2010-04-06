package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.Observable;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	public class TimeIntervalFixture
	{
		[Test(async)]
		public function value_is_wrapped_in_time_interval() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.interval(10).take(5)
				.timeInterval()
				.subscribe(stats);
					
			Assert.assertFalse(stats.nextCalled);

			Async.asyncHandler(this, function():void {}, 200, null, function():void
			{
				Assert.assertEquals(5, stats.nextCount);
				Assert.assertTrue(stats.nextValues[0].interval == 0);
				Assert.assertTrue(stats.nextValues[1].interval >= 10);
				Assert.assertTrue(stats.nextValues[2].interval >= 10);
				Assert.assertTrue(stats.nextValues[3].interval >= 10);
				Assert.assertTrue(stats.nextValues[4].interval >= 10);
				Assert.assertTrue(stats.completedCalled);
			});
		}
	}
}