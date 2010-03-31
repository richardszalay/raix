package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class DoActionFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.doAction(null);
		}
		
		[Test]
		public function next_action_is_called_before_observer() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var actionCalled : Boolean = false;
			var observerCalled : Boolean = false; 
			
			manObs
				.doAction(function(pl:Object):void { Assert.assertFalse(observerCalled); actionCalled = true; })
				.subscribeFunc(function(pl:Object):void { Assert.assertTrue(actionCalled); observerCalled = true; })
			
			manObs.onNext(0);
			
			Assert.assertTrue(actionCalled);
			Assert.assertTrue(observerCalled);
		}
		
		[Test]
		public function complete_action_is_called_before_observer() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var actionCalled : Boolean = false;
			var observerCalled : Boolean = false; 
			
			manObs
				.doAction(null, function():void { Assert.assertFalse(observerCalled); actionCalled = true; })
				.subscribeFunc(null, function():void { Assert.assertTrue(actionCalled); observerCalled = true; })
			
			manObs.onCompleted();
			
			Assert.assertTrue(actionCalled);
			Assert.assertTrue(observerCalled);
		}
		
		[Test]
		public function error_action_is_called_before_observer() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var actionCalled : Boolean = false;
			var observerCalled : Boolean = false; 
			
			manObs
				.doAction(null, null, function(pl:Error):void { Assert.assertFalse(observerCalled); actionCalled = true; })
				.subscribeFunc(null, null, function(pl:Error):void { Assert.assertTrue(actionCalled); observerCalled = true; })
			
			manObs.onError(new Error());
			
			Assert.assertTrue(actionCalled);
			Assert.assertTrue(observerCalled);
		}
		
		[Test]
		public function error_thrown_in_next_action_is_sent_to_on_error() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var actionCalled : Boolean = false;
			var observerCalled : Boolean = false; 
			
			var stats : StatsObserver = new StatsObserver();
			
			manObs
				.doAction(function(pl:Object):void { throw new Error(); })
				.subscribe(stats)
			
			manObs.onNext(0);
			
			Assert.assertTrue(stats.errorCalled);
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