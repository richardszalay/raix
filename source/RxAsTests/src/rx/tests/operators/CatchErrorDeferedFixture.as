package rx.tests.operators
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class CatchErrorDeferedFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.catchErrorDefer(Error, function(e:Error):IObservable
			{
				return Observable.throwError(e, source.valueClass);
			});
		}
		
		[Test]
		public function catch_with_action_does_not_fire_onerror() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefer(Error, function(e:Error):IObservable { return Observable.empty(int); })
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefer(Error, function(e:Error):IObservable
				{
					return Observable.throwError(new IllegalOperationError(), int);
				})
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_action_throws_exception() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefer(Error, function(e:Error):IObservable
				{
					throw new IllegalOperationError();
				})
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_action_fires_original_error_if_action_returns_null() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefer(Error, function(e:Error):IObservable
				{
					return null;
				})
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is Error);
		}
		
		[Test]
		public function catch_with_action_fires_original_error_if_error_is_not_of_specified_type() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new IllegalOperationError(), int)
				.catchErrorDefer(ArgumentError, function(e:Error):IObservable
				{
					return null;
				})
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.contains(0, function(a:int,b:int) : Boolean
			{
				return true;
			});
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}