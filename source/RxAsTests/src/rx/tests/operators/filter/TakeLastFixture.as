package rx.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class TakeLastFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.takeLast(3);
		}
		
		[Test]
		public function complete_is_called_after_source_completes() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.takeLast(3);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(0);
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertFalse(stats.completedCalled);
			
			manObs.onCompleted();
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function last_count_values_are_emitted() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.takeLast(3);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onCompleted();
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(1, stats.nextValues[0]);
			Assert.assertEquals(2, stats.nextValues[1]);
			Assert.assertEquals(3, stats.nextValues[2]);
		}

        [Test(expects="ArgumentError")]
        public function take_zero_throws_argument_exception() : void
        {
            Observable.range(0, 5).takeLast(0);
        }

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.takeLast(3);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
			manObs.onCompleted();
		}
	}
}