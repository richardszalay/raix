package raix.reactive.tests.operators.errors
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class CatchErrorDeferedFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.catchErrorDefer(Error, function(e:Error):IObservable
			{
				return Observable.error(e);
			});
		}
		
		[Test]
		public function catch_with_action_does_not_fire_onerror() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.error(new Error())
				.catchErrorDefer(Error, function(e:Error):IObservable { return Observable.empty(); })
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.error(new Error())
				.catchErrorDefer(Error, function(e:Error):IObservable
				{
					return Observable.error(new IllegalOperationError());
				})
				.subscribeWith(stats);
			
			Assert.assertTrue(stats.errorCalled);
			Assert.assertTrue(stats.error is IllegalOperationError);
		}
		
		[Test]
		public function catch_with_action_fires_error_if_action_throws_exception() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.error(new Error())
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
			
			Observable.error(new Error())
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
			
			Observable.error(new IllegalOperationError())
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
			var manObs : Subject = new Subject();
			
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