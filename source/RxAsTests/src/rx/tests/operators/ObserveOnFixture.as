package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.scheduling.ImmediateScheduler;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	public class ObserveOnFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.observeOn(ImmediateScheduler.instance);
		}
		
		[Test]
		public function subscriptions_go_through_scheduler() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribe(stats);
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test]
		public function cancelling_before_subscription_cancels_schedule() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			var subscription : ISubscription = obs.subscribe(stats);
			
			subscription.unsubscribe();
			
			scheduler.runNext();
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function cancelling_after_subscription_unsubscribes_from_source() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			var subscription : ISubscription = obs.subscribe(stats);
			
			scheduler.runNext();
			Assert.assertTrue(manObs.hasSubscriptions);
			
			subscription.unsubscribe();
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

	}
}