package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ICancelable;
	import rx.scheduling.ImmediateScheduler;
	import rx.Subject;
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
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test]
		public function cancelling_before_subscription_cancels_schedule() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			var subscription : ICancelable = obs.subscribeWith(stats);
			
			subscription.cancel();
			
			scheduler.runNext();
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function cancelling_after_subscription_unsubscribes_from_source() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			var subscription : ICancelable = obs.subscribeWith(stats);
			
			scheduler.runNext();
			Assert.assertTrue(manObs.hasSubscriptions);
			
			subscription.cancel();
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

	}
}