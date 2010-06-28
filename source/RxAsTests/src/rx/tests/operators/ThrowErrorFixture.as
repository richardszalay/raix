package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	
	public class ThrowErrorFixture
	{
		[Test]
		public function error_is_thrown_on_subscribe() : void
		{
			var err : Error = new Error();
			var obs : IObservable = Observable.throwError(err);
			
			var errorCalled : Boolean = false,
				nextCalled : Boolean = false,
				completeCalled : Boolean = false;
				
			obs.subscribe(
				function(pl:Object):void { nextCalled = true; },
				function():void { completeCalled = true; },
				function(e:Error):void { errorCalled = true; Assert.assertStrictlyEquals(err, e); }
				);
				
			Assert.assertTrue(errorCalled);
		}
	}
}