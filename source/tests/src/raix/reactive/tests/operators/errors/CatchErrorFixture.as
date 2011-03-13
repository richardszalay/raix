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
				.subscribeWith(stats);
			
			Assert.assertFalse(stats.errorCalled);
		}
		
		[Test]
		public function catch_with_observer_fires_error_if_last_observer_raises_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int)
				.catchError(Observable.throwError(new IllegalOperationError(), int))
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