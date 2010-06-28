package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	
	[TestCase]
	public class WhereFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.where(function(pl:Object) : Boolean { return true; });
		}
		
		[Test]
		public function values_are_filtered_by_predicate() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.where(function(pl:uint) : Boolean
			{
				return (pl % 2) == 0;
			});
			
			var expectedValues : Array = [0, 2, 4, 6, 8];
			var nextCount : uint = 0;
			
			obs.subscribe(function(pl:int):void
			{
				nextCount++;
				Assert.assertEquals(expectedValues.shift(), pl);
			});
			
			for (var i:int=0; i<10; i++)
			{
				manObs.onNext(i);
			}
			
			Assert.assertEquals(5, nextCount);
		}
		
		[Test]
		public function errors_thrown_by_predicate_are_sent_to_onerror() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.where(function(pl:uint) : Boolean
			{
				throw new Error();
			});
			
			var nextCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			obs.subscribe(
				function(pl:int):void { nextCalled = true; },
				function():void { },
				function(e:Error):void { errorCalled = true; }
			);

			manObs.onNext(0);
			
			Assert.assertFalse(nextCalled);
			Assert.assertTrue(errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.where(function(pl:uint) : Boolean
			{
				return true;
			});
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}