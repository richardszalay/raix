package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	
	public class FinallyActionFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.finallyAction(function():void{});
		}
		
		[Test]
		public function action_is_called_on_completed_before_observer() : void
		{
			var finallyCalled : Boolean = true;
			var completedCalled : Boolean = true;
			
			Observable.empty(int)
				.finallyAction(function():void { finallyCalled = true; })
				.subscribeFunc(null, 
					function():void { Assert.assertTrue(finallyCalled); completedCalled = true; } 
					);
					
			Assert.assertTrue(finallyCalled);
			Assert.assertTrue(completedCalled);
		}
		
		[Test]
		public function action_is_called_on_error_before_observer() : void
		{
			var finallyCalled : Boolean = true;
			var errorCalled : Boolean = true;
			
			Observable.throwError(new Error(), int)
				.finallyAction(function():void { finallyCalled = true; })
				.subscribeFunc(null, null,
					function(e:Error):void { Assert.assertTrue(finallyCalled); errorCalled = true; } 
					);
					
			Assert.assertTrue(finallyCalled);
			Assert.assertTrue(errorCalled);
		}
		
		[Test(expects="ArgumentError")]
		public function error_is_thrown_if_action_is_null() : void
		{
			Observable.empty(int).finallyAction(null);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_finallyAction_are_bubbled() : void
		{	
			var obs : IObservable = Observable.empty(int).finallyAction(function():void
			{
				throw new Error();
			});
			
			obs.subscribeFunc(
				function(pl:int):void { },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var obs : IObservable = Observable.range(0, 1)
				.finallyAction(function():void{});
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}

	}
}