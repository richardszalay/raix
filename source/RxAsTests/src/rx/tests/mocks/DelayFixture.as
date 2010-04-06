package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.Observable;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	public class DelayFixture
	{
		[Test(async)]
		public function action_is_executed_after_delay() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.returnValue(int, 1)
				.delay(200)
				.subscribe(stats);
					
			Assert.assertFalse(stats.nextCalled);

			Async.asyncHandler(this, function():void {}, 210, null, function():void
			{
				Assert.assertTrue(stats.nextCalled);
			});
		}
		
		[Test(async)]
		public function delay_is_cancelled_on_unsubscribe() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.returnValue(int, 1)
				.delay(100)
				.subscribe(stats)
				.unsubscribe();

			Async.asyncHandler(this, function():void {}, 210, null, function():void
			{
				Assert.assertFalse(stats.nextCalled);
			});
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = Observable.returnValue(int, 1).delay(50, scheduler);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
			
			scheduler.runAll();
		}

	}
}