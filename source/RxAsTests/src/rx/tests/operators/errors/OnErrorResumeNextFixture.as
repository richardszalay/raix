package rx.tests.operators.errors
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class OnErrorResumeNextFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.onErrorResumeNext(Observable.throwError(new Error()));
		}
		
		[Test]
		public function does_not_fire_onerror_if_last_observer_completes() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.onErrorResumeNext(Observable.empty(int))
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.onErrorResumeNext(Observable.throwError(new IllegalOperationError(), int))
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function subscribes_to_first_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			manObs
				.onErrorResumeNext(Observable.throwError(new IllegalOperationError(), int), scheduler)
				.subscribeWith(stats);
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test]
		public function subscribes_to_next_through_scheduler() : void
		{
			var manObs : Subject = new Subject(int);
			
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.onErrorResumeNext(manObs, scheduler)
				.subscribeWith(stats);
			
			scheduler.runNext();
			
			Assert.assertFalse(manObs.hasSubscriptions);
			
			scheduler.runNext();
			
			Assert.assertTrue(manObs.hasSubscriptions);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.onErrorResumeNext(Observable.empty(int));
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
		
		[Test]
		public override function is_normalized_for_oncompleted() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.onErrorResumeNext(Observable.empty(int));
			
			var nextCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			obs.subscribe(
				function(pl:int):void { nextCalled = true; },
				function():void { },
				function(e:Error):void { errorCalled = true; }
			);
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertFalse(nextCalled);
			Assert.assertFalse(errorCalled);
		}
	}
}