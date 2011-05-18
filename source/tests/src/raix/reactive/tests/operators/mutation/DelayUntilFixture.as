package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class DelayUntilFixture
	{
		[Test(async)]
		public function action_is_executed_after_delay() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var untilDate : Date = new Date(new Date().time + 200);
			
			Observable.value(1)
				.delayUntil(untilDate)
				.subscribe(stats);
	
			Assert.assertFalse(stats.nextCalled);

			Async.asyncHandler(this, function():void {}, 210, null, function():void
			{
				Assert.assertTrue(stats.nextCalled);
			});
		}
		
		[Test]
		public function action_is_immediately_if_date_is_past() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var untilDate : Date = new Date(new Date().time - 200);
			
			Observable.value(1)
				.delayUntil(untilDate)
				.subscribe(stats);
					
			Assert.assertTrue(stats.nextCalled);
		}
		
		[Test(async)]
		public function delay_is_cancelled_on_unsubscribe() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var untilDate : Date = new Date(new Date().time + 200);
			
			Observable.value(1)
				.delayUntil(untilDate)
				.subscribe(stats)
				.cancel();				

			Async.asyncHandler(this, function():void {}, 210, null, function():void
			{
				Assert.assertFalse(stats.nextCalled);
			});
		}
		
		[Test(async)]
		public function all_values_are_cancelled_on_unsubscribe() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var untilDate : Date = new Date(new Date().time + 200);
			
			Observable.range(0, 2)
				.delayUntil(untilDate)
				.subscribe(stats)
				.cancel();				

			Async.asyncHandler(this, function():void {}, 210, null, function():void
			{
				Assert.assertFalse(stats.nextCalled);
			});
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var untilDate : Date = new Date(new Date().time + 200);
			
			var obs : IObservable = Observable.value(1).delayUntil(untilDate, scheduler);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
			
			scheduler.runAll();
		}

	}
}