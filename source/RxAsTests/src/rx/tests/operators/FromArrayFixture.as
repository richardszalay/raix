package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.tests.mocks.StatsObserver;
	
	public class FromArrayFixture
	{
		[Test]
		public function emits_values_from_source_array() : void
		{
			var array : Array = ["right", "said", "fred"];
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.fromArray(String, array)
				.subscribe(stats);
				
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals("right", stats.nextValues[0]);
			Assert.assertEquals("said", stats.nextValues[1]);
			Assert.assertEquals("fred", stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function mutating_original_array_does_not_affect_output() : void
		{
			var array : Array = ["right", "said", "fred"];
			
			var stats : StatsObserver = new StatsObserver();
			
			var observable : IObservable = Observable.fromArray(String, array);
			array.pop();
			
			observable.subscribe(stats);
				
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals("right", stats.nextValues[0]);
			Assert.assertEquals("said", stats.nextValues[1]);
			Assert.assertEquals("fred", stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
	}
}