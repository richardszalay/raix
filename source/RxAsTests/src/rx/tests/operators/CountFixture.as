package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ICancelable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class CountFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.count();
		}
		
		[Test]
		public function value_equals_number_of_values() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(5, 3).count().subscribeWith(stats);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function value_is_not_sent_until_completion() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.never(int).count().subscribeWith(stats);
			
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function zero_is_sent_if_no_values_received() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.empty(int).count().subscribeWith(stats);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function value_is_not_sent_on_error() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.throwError(new Error(), int).count().subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertTrue(stats.errorCalled);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.count();
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
			manObs.onCompleted();
		}
		
		[Test]
		public override function is_normalized_for_oncompleted() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var nextCount : int = 0;
			var errorCalled : Boolean = false;
			
			var subs : ICancelable = obs.subscribe(
				function(pl:int):void { nextCount++; },
				function():void { },
				function(e:Error):void { errorCalled = true; }
			);
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, nextCount);
			Assert.assertFalse(errorCalled);
		}
	}
}