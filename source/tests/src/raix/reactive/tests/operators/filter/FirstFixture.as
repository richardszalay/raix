package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class FirstFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.first();
		}
		
		[Test]
		public function returns_first_value_and_completes() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.first();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(1);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function returns_error_if_no_values() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.first();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onCompleted();
			
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.asObservable();
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
		
		[Test]
		public override function is_normalized_for_oncompleted() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(new Object());
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(1, stats.completedCalled);
			Assert.assertFalse(stats.errorCalled);
		}

	}
}