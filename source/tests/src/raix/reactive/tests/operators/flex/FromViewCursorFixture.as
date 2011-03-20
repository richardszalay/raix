package raix.reactive.tests.operators.flex
{
	import mx.collections.ArrayCollection;
	
	import org.flexunit.Assert;
	
	import raix.reactive.flex.FlexObservable;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class FromViewCursorFixture
	{
		[Test]
		public function emits_each_value_of_the_cursor() : void
		{
			var collection : ArrayCollection = new ArrayCollection();
			collection.addItem("right");
			collection.addItem("said");
			collection.addItem("fred");
			
			var stats : StatsObserver = new StatsObserver();
			
			FlexObservable.fromViewCursor(collection.createCursor())
				.subscribeWith(stats);
				
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals("right", stats.nextValues[0]);
			Assert.assertEquals("said", stats.nextValues[1]);
			Assert.assertEquals("fred", stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
	}
}