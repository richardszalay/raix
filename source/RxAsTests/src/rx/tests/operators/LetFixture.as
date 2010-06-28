package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class LetFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.let(function(x:IObservable) : IObservable
			{
				return x.select(int, function(y:int):int { return y; });
			});
		}
		
		[Test]
		public function sends_current_observable_as_function_argument() : void
		{
			var manObs : Subject = new Subject(int);
			
			manObs.let(function(x:IObservable) : IObservable
			{
				Assert.assertStrictlyEquals(manObs, x);
				
				return x;
			});
		}
		
		[Test]
		public function returns_function_result_as_observable() : void
		{
			var manObsA : Subject = new Subject(int);
			var manObsB: Subject = new Subject(int);
			
			var obs : IObservable = manObsA.let(function(x:IObservable) : IObservable
			{
				return manObsB;
			});
			
			Assert.assertStrictlyEquals(manObsB, obs);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObsA.onNext(0);	
			manObsB.onNext(1);
			
			Assert.assertEquals(1, stats.nextCount);
			
		}

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}
