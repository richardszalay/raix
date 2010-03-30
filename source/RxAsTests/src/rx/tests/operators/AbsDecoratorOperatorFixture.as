package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.tests.mocks.ManualObservable;
	
	// Includes common tests for all decorator operators
	public class AbsDecoratorOperatorFixture
	{
		public function AbsDecoratorOperatorFixture()
		{
		}
		
		[Test]
		public function unsubscribes_from_source_on_completed() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onCompleted();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_error() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onError(new Error());
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_unsubscribe() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var subs : ISubscription = obs.subscribeFunc(function(pl:int):void
			{
			});
			
			subs.unsubscribe();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function is_normalized_for_oncompleted() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var nextCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			var subs : ISubscription = obs.subscribeFunc(
				function(pl:int):void { nextCalled = true; },
				function():void { },
				function(e:Error):void { errorCalled = true; }
			);
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertFalse(nextCalled);
			Assert.assertFalse(errorCalled);
		}
		
		[Test]
		public function is_normalized_for_onerror() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var nextCalled : Boolean = false;
			var completedCalled : Boolean = false;
			
			var subs : ISubscription = obs.subscribeFunc(
				function(pl:int):void { nextCalled = true; },
				function():void { completedCalled = true; },
				function(e:Error):void { }
			);
			
			manObs.onError(new Error());
			manObs.onNext(new Object());
			manObs.onCompleted();
			
			Assert.assertFalse(nextCalled);
			Assert.assertFalse(completedCalled);
		}
		
		protected function createEmptyObservable(source : IObservable) : IObservable
		{
			Assert.fail("createEmptyObservable must be overriden");
			
			return null;
		}
	}
}