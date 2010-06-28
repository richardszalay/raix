package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ICancelable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class RangeFixture
	{
		[Test]
		public function dispatches_one_value_within_range() : void
		{
			var obs : IObservable = Observable.range(2, 7);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats); 
			
			Assert.assertEquals(7, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0]);
			Assert.assertEquals(3, stats.nextValues[1]);
			Assert.assertEquals(4, stats.nextValues[2]);
			Assert.assertEquals(5, stats.nextValues[3]);
			Assert.assertEquals(6, stats.nextValues[4]);
			Assert.assertEquals(7, stats.nextValues[5]);
			Assert.assertEquals(8, stats.nextValues[6]);
			
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function unsubscribing_stops_range_items_in_motion() : void
		{
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = Observable.range(2, 7, scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = obs.subscribeWith(stats); 
			
			Assert.assertFalse(stats.nextCalled);
			
			scheduler.runNext();
			scheduler.runNext();
			scheduler.runNext();
			subscription.cancel();
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(2, stats.nextValues[0]);
			Assert.assertEquals(3, stats.nextValues[1]);
			Assert.assertEquals(4, stats.nextValues[2]);
			
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.range(0, 1);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_observable_factory_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.defer(int, function():IObservable
			{
				throw new Error();
			});
			
			obs.subscribe(
				function(pl:int):void { },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
	}
}