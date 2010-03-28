package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class BufferWithCountFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.bufferWithCount(1);
		}
		
		[Test]
		public function values_are_buffered_in_specified_groups() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.bufferWithCount(3);
			
			var expectedValues : Array = [
				[0, 1, 2],
				[3, 4, 5]
				];
				
			var nextCount : uint = 0;
			
			obs.subscribeFunc(function(pl:Array):void
			{
				var expectedArr : Array = expectedValues.shift();
				
				Assert.assertEquals(expectedArr[0], pl[0]);
				Assert.assertEquals(expectedArr[1], pl[1]);
				Assert.assertEquals(expectedArr[2], pl[2]);

			});
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onNext(4);
			manObs.onNext(5);
		}
		
		[Test]
		public function skip_value_is_honoured() : void
		{
			Assert.fail("Test not implemented. Need to see how this reacts in Rx.Net");
		}
		
		[Test(expects="ArgumentError")]
		public function argument_error_is_thrown_if_bufferSize_is_zero() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.bufferWithCount(0);
		}
				
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.bufferWithCount(1);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}