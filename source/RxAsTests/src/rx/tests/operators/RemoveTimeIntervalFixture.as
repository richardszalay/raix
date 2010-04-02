package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class RemoveTimeIntervalFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.timeInterval().removeTimeInterval(source.type);
		}
		
		[Test]
		public function original_values_are_used() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.timeInterval().removeTimeInterval(int);
			
			var expectedValues : Array = [1, 2, 3, 4];
			
			obs.subscribeFunc(function(pl:int):void
			{
				Assert.assertEquals(expectedValues.shift(), pl);
			});
			
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onNext(4);
			
			Assert.assertEquals(0, expectedValues.length);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.timeInterval().removeTimeInterval(int);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}