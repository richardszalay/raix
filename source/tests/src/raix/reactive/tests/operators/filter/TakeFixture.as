package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class TakeFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.take(3);
		}
		
		[Test]
		public function complete_is_called_after_specified_values_taken() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.take(3);
			
			var nextCount : uint = 0;
			var completeCalled : Boolean = false;
			
			obs.subscribe(
				function(pl:int):void { nextCount++; },
				function():void { completeCalled = true; }	
			);
			
			manObs.onNext(0);
			Assert.assertEquals(1, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(2, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(3, nextCount);
			Assert.assertTrue(completeCalled);
		}

        [Test(expets="ArgumentError")]
        public function take_zero_throws_argument_exception() : void
        {
            Observable.range(0, 5).take(0);
        }

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.take(3);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}