package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class MergeFixture
	{
		[Test]
		public function values_are_merged_in_order() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.mergeMany(int, Observable.fromArray(IObservable, [
				Observable.range(0, 3),
				Observable.range(3, 3),
				Observable.range(6, 3),
			]))
			.subscribeWith(stats);
			
			Assert.assertEquals(9, stats.nextCount);
			// TODO: This can't be right... first two for each sequence seem to go before the merge
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertEquals(3, stats.nextValues[2]);
			Assert.assertEquals(2, stats.nextValues[3]);
			Assert.assertEquals(4, stats.nextValues[4]);
			Assert.assertEquals(6, stats.nextValues[5]);
		}
	}
}