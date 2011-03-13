package raix.reactive.tests.operators.scheduling
{
	import org.flexunit.Assert;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.scheduling.ImmediateScheduler;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class SubscribeOnFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.subscribeOn(ImmediateScheduler.instance);
		}
		
		[Test]
		public function subscriptions_go_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.subscribeOn(scheduler);
			
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
			
			var obs : IObservable = manObs.subscribeOn(scheduler);
			
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
			
			var obs : IObservable = manObs.subscribeOn(scheduler);
			
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