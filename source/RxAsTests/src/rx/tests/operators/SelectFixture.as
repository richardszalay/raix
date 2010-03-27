package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class SelectFixture
	{
		[Test]
		public function maps_value_using_function() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var index : int = 0;
			
			var obs : IObservable = manObs.select(function(pl:Object) : int
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
		public function unsubscribes_from_source_on_completed() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var index : int = 0;
			
			var obs : IObservable = manObs.select(function(pl:Object) : int { return 0; });
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onCompleted();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_error() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var index : int = 0;
			
			var obs : IObservable = manObs.select(function(pl:Object) : int { return 0; });
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onError(new Error());
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_unsubscribe() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var index : int = 0;
			
			var obs : IObservable = manObs.select(function(pl:Object) : int { return 0; });
			
			var subs : ISubscription = obs.subscribeFunc(function(pl:int):void
			{
			});
			
			subs.unsubscribe();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
	}
}