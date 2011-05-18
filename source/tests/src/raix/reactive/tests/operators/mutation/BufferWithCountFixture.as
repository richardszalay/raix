package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
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
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(3);
			
			var expectedValues : Array = [
				[0, 1, 2],
				[3, 4, 5]
				];
				
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onNext(4);
			manObs.onNext(5);
			manObs.onCompleted();
		}
		
		[Test]
		public function skip_value_is_honoured_when_less_than_count() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(2, 1);
			
			var expectedValues : Array = [
				[0, 1],
				[1, 2],
				[2, 3],
				[3]
				];
				
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onCompleted();
		}
		
		[Test]
		public function skip_value_is_honoured_when_equal_to_count() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(2, 2);
			
			var expectedValues : Array = [
				[0, 1],
				[2, 3],
				];
				
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onCompleted();
		}
		
		[Test]
		public function skip_value_is_honoured_when_greater_than_count() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(2, 3);
			
			var expectedValues : Array = [
				[0, 1],
				[3],
				];
				
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onCompleted();
		}
		
		[Test]
		public function remaining_items_are_released_on_completed() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(2);
			
			var expectedValues : Array = [
				[0, 1],
				[2]
				];
				
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onCompleted();
		}
		
		[Test]
		public function remaining_items_are_not_released_on_error() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(2);
			
			var expectedValues : Array = [
				[0, 1]
				];
			
			testBufferResults(obs, expectedValues);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onError(new Error());
		}
		
		private function testBufferResults(obs : IObservable, expectedValues : Array) : void
		{
			var nextCount : int = 0;
			
			var expectedValueCount : int = expectedValues.length;
			
			obs.subscribe(
				function(pl:Array):void
				{
					nextCount++;
					
					var expectedArr : Array = expectedValues.shift();
					
					Assert.assertEquals(expectedArr.length, pl.length);
					
					for (var i:int=0; i<pl.length; i++)
					{
						Assert.assertEquals(expectedArr[i], expectedArr[i]);
					}
				},
				function():void
				{
					Assert.assertEquals("incorrect number of values", expectedValueCount, nextCount);
				},
				function(e:Error):void
				{
					Assert.assertEquals("incorrect number of values", expectedValueCount, nextCount);
				}
			);
		}
		
		[Test(expects="ArgumentError")]
		public function argument_error_is_thrown_if_bufferSize_is_zero() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(0);
		}
				
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.bufferWithCount(1);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}
