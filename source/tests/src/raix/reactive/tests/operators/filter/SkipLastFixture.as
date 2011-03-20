package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class SkipLastFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.skip(0);
		}
		
		[Test]
		public function last_count_values_are_skipped() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 5).skipLast(3).subscribeWith(stats);
			
			Assert.assertEquals(2, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function sequence_can_complete_before_enough_values() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 2).skipLast(3).subscribeWith(stats);
			
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function no_values_are_emitted_on_empty_sequence() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.empty().skipLast(3).subscribeWith(stats);
			
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var obs : IObservable = Observable.range(0, 2).skip(1);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
	}
}