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
		[Test]
		public function action_is_executed_after_delay() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.returnValue(int, 1)
				.delay(200, scheduler)
				.subscribe(stats);
					
			Assert.assertFalse(stats.nextCalled);
			
			scheduler.runNext();
			Assert.assertTrue(stats.nextCalled);
		}
		
		[Test]
		public function delay_is_cancelled_on_unsubscribe() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ISubscription = Observable.returnValue(int, 1)
				.delay(100, scheduler)
				.subscribe(stats);
				
			Assert.assertEquals(1, scheduler.queueSize);
			
			subscription.unsubscribe();
			Assert.assertEquals(0, scheduler.queueSize);
		}
		
		[Test(async)]
		public function all_values_are_cancelled_on_unsubscribe() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 2)
				.delay(200)
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