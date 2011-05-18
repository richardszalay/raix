package raix.reactive.tests.operators.flex
{
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	
	import org.flexunit.Assert;
	
	import raix.reactive.flex.FlexObservable;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class FromListFixture
	{
		[Test]
		public function emits_each_value_of_the_list() : void
		{
			var list : ArrayList = new ArrayList();
			list.addItem("right");
			list.addItem("said");
			list.addItem("fred");

			var stats : StatsObserver = new StatsObserver();

			FlexObservable.fromList(String, list)
				.subscribeWith(stats);

			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals("right", stats.nextValues[0]);
			Assert.assertEquals("said", stats.nextValues[1]);
			Assert.assertEquals("fred", stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
	}
}