package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class SkipFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.skip(0);
		}
		
		[Test]
		public function next_is_not_called_until_after_specified_number_of_values() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 5).skip(3).subscribeWith(stats);
			
			Assert.assertEquals(2, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0]);
			Assert.assertEquals(4, stats.nextValues[1]);
		}
		
		[Test]
		public function sequence_can_complete_before_enough_values() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 3).skip(3).subscribeWith(stats);
			
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