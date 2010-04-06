package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	
	[TestCase]
	public class TakeWhileFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.takeWhile(function(pl:Object) : Boolean { return true; });
		}
		
		[Test]
		public function values_are_returned_until_predicate_returns_false() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.takeWhile(function(pl:uint) : Boolean
			{
				return pl < 5;
			});
			
			var nextCount : uint = 0;
			
			obs.subscribeFunc(function(pl:int):void
			{
				nextCount++;
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
			
			var obs : IObservable = manObs.takeWhile(function(pl:uint) : Boolean
			{
				throw new Error();
			});
			
			var nextCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			obs.subscribeFunc(
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
			
			var obs : IObservable = manObs.takeWhile(function(pl:uint) : Boolean
			{
				return true;
			});
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}