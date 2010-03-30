package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class SelectFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.select(source.type, function(pl:Object) : Object { return pl; });
		}
		
		[Test]
		public function maps_value_using_function() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.select(int, function(pl:Object) : int
			{
				return index++;
			});
			
			obs.subscribeFunc(function(pl:int):void
			{
				Assert.assertEquals(index-1, pl);	
			});
			
			for (var i:int=0; i<10; i++)
			{
				manObs.onNext(Math.random());
			}
		}
		
		[Test]
		public function errors_thrown_by_predicate_are_sent_to_onerror() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.select(Object, function(pl:uint) : Boolean
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
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.select(Boolean, function(pl:uint) : Boolean
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