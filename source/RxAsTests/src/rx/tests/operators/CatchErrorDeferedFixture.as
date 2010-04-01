package rx.tests.operators
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class CatchErrorDeferedFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.catchErrorDefered(Error, function(e:Error):IObservable
			{
				return Observable.throwError(e, source.type);
			});
		}
		
		[Test]
		public function catch_with_action_does_not_fire_onerror() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefered(Error, function(e:Error):IObservable { return Observable.empty(int); })
				.subscribe(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefered(Error, function(e:Error):IObservable
				{
					return Observable.throwError(new IllegalOperationError(), int);
				})
				.subscribe(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_action_throws_exception() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefered(Error, function(e:Error):IObservable
				{
					throw new IllegalOperationError();
				})
				.subscribe(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_action_fires_original_error_if_action_returns_null() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchErrorDefered(Error, function(e:Error):IObservable
				{
					return null;
				})
				.subscribe(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is Error);
		}
		
		[Test]
		public function catch_with_action_fires_original_error_if_error_is_not_of_specified_type() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new IllegalOperationError(), int)
				.catchErrorDefered(ArgumentError, function(e:Error):IObservable
				{
					return null;
				})
				.subscribe(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
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