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
	
	public class ObserveOnFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.observeOn(ImmediateScheduler.instance);
		}
		
		[Test]
		public function subscriptions_are_not_affected_by_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			manObs.observeOn(scheduler).subscribeWith(stats);
			
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test]
		public function values_are_sent_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = manObs
				.observeOn(scheduler)
				.subscribeWith(stats);
			
			manObs.onNext(0);
			
			Assert.assertFalse(stats.nextCount);
			
			scheduler.runNext();
			
			Assert.assertTrue(stats.nextCount);
		}
		
		[Test]
		public function completed_is_sent_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = manObs
				.observeOn(scheduler)
				.subscribeWith(stats);
			
			manObs.onCompleted();
			
			Assert.assertFalse(stats.completedCalled);
			
			scheduler.runNext();
			
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function error_is_sent_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = manObs
				.observeOn(scheduler)
				.subscribeWith(stats);
			
			manObs.onError(new Error());
			
			Assert.assertFalse(stats.errorCalled);
			
			scheduler.runNext();
			
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test]
		public function cancelling_after_subscription_unsubscribes_from_source() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var obs : IObservable = manObs.observeOn(scheduler);
			
			var subscription : ICancelable = manObs
				.observeOn(scheduler)
				.subscribeWith(stats);
			
			Assert.assertTrue(manObs.hasSubscriptions);
			
			subscription.cancel();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function cancelling_stops_values_in_flight() : void
		{
			var manObs : Subject = new Subject(int);
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = manObs
				.observeOn(scheduler)
				.subscribeWith(stats);
				
			manObs.onNext(0);
			manObs.onCompleted();
			
			subscription.cancel();
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertFalse(stats.completedCalled);
			Assert.assertEquals(0, scheduler.queueSize);
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