package rx.tests.operators
{
	import mx.collections.ArrayCollection;
	
	import org.flexunit.Assert;
	
	import rx.Observable;
	import rx.tests.mocks.StatsObserver;
	
	public class FromCollectionFixture
	{
		[Test]
		public function asd() : void
		{
			var collection : ArrayCollection = new ArrayCollection();
			collection.addItem("right");
			collection.addItem("said");
			collection.addItem("fred");
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.fromCollection(String, collection)
				.subscribeWith(stats);
				
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals("right", stats.nextValues[0]);
			Assert.assertEquals("said", stats.nextValues[1]);
			Assert.assertEquals("fred", stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
	}
}