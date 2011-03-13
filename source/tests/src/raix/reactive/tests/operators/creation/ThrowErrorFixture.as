package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ThrowErrorFixture
	{
		[Test]
		public function error_is_thrown_on_subscribe() : void
		{
			var err : Error = new Error();
			var obs : IObservable = Observable.throwError(err);
			
			var stats : StatsObserver = new StatsObserver();
				
			obs.subscribeWith(stats);
				
			Assert.assertTrue(stats.errorCalled);
			Assert.assertStrictlyEquals(err, stats.error);
		}
	}
}