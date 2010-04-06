package rx.tests.operators
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class CatchErrorFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.catchError(Observable.throwError(new Error()));
		}
		
		[Test]
		public function catch_with_observer_does_not_fire_onerror() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchError(Observable.empty(int))
				.subscribe(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function catch_with_observer_fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchError(Observable.throwError(new IllegalOperationError(), int))
				.subscribe(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_observer_subscribes_to_first_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			manObs
				.catchError(Observable.throwError(new IllegalOperationError(), int), scheduler)
				.subscribe(stats);
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test]
		public function catch_with_observer_subscribes_to_next_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchError(manObs, scheduler)
				.subscribe(stats);
			
			scheduler.runNext();
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.contains(0, function(a:int,b:int) : Boolean
			{
				return true;
			});
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}