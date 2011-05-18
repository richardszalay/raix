package raix.reactive.tests.operators.errors
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class TimeoutFixture
	{
		[Test(async)]
		public function error_is_raised_after_specified_amount_of_time() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.never()
				.timeout(100)
				.subscribeWith(stats);
				
			Async.asyncHandler(this, function():void{}, 150, null, function():void
			{
				Assert.assertTrue(stats.errorCalled);
			});
		}
		
		[Test(async)]
		public function other_observable_is_attached_after_specified_amount_of_time() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.never()
				.timeout(100, Observable.range(0, 2))
				.subscribeWith(stats);
				
			Async.asyncHandler(this, function():void{}, 150, null, function():void
			{
				Assert.assertEquals(2, stats.nextCount);
				Assert.assertFalse(stats.errorCalled);
				Assert.assertTrue(stats.completedCalled);
			});
		}
		
		[Test]
		public function other_observable_is_not_subscribed_to_until_timeout() : void
		{
			var otherObs : Subject = new Subject();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = Observable.never()
				.timeout(100, Observable.range(0, 2))
				.subscribeWith(stats);
			
			Assert.assertFalse(otherObs.hasSubscriptions);
			
			subscription.cancel();
		}
	}
}