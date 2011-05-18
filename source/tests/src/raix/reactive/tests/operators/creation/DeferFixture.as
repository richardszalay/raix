package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class DeferFixture
	{
		[Test]
		public function defer_function_is_called_for_every_observable() : void
		{
			var manObsA : Subject = new Subject();
			var manObsB : Subject = new Subject();
			
			var observables : Array = [manObsA, manObsB];
			
			var defObs : IObservable = Observable.defer(function():IObservable
			{
				return IObservable(observables.shift());
			});
			
			var statsA : StatsObserver = new StatsObserver();
			var statsB : StatsObserver = new StatsObserver();
			
			defObs.subscribeWith(statsA);
			defObs.subscribeWith(statsB);
			
			manObsA.onNext(1);			
			manObsB.onNext(5);
			
			Assert.assertEquals(1, statsA.nextCalled);
			Assert.assertEquals(1, statsA.nextValues[0]);
			
			Assert.assertEquals(1, statsB.nextCalled);
			Assert.assertEquals(5, statsB.nextValues[0]);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = Observable.defer(function():IObservable { return manObs; });
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_observable_factory_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = Observable.defer(function():IObservable
			{
				throw new Error();
			});
			
			obs.subscribe(
				function(pl:int):void { },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
	}
}