package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class DeferFixture
	{
		[Test]
		public function defer_function_is_called_for_every_observable() : void
		{
			var manObsA : Subject = new Subject(int);
			var manObsB : Subject = new Subject(int);
			
			var observables : Array = [manObsA, manObsB];
			
			var defObs : IObservable = Observable.defer(int, function():IObservable
			{
				return IObservable(observables.shift());
			});
			
			var statsA : StatsObserver = new StatsObserver();
			var statsB : StatsObserver = new StatsObserver();
			
			defObs.subscribe(statsA);
			defObs.subscribe(statsB);
			
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
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.defer(int, function():IObservable { return manObs; });
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_observable_factory_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.defer(int, function():IObservable
			{
				throw new Error();
			});
			
			obs.subscribeFunc(
				function(pl:int):void { },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
	}
}