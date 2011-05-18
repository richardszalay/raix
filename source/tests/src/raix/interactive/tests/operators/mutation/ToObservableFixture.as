package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	
	import org.flexunit.Assert;
	
	import raix.reactive.scheduling.Scheduler;
	import raix.reactive.tests.AssertEx;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class ToObservableFixture
	{
		[Test]
		public function converts_enumerator_to_observable() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Enumerable.range(0, 2)
				.toObservable(Scheduler.immediate)
				.subscribeWith(stats);
				
			Assert.assertEquals(2, stats.nextCount);
			AssertEx.assertArrayEquals([0, 1], stats.nextValues);
		}
	}
}