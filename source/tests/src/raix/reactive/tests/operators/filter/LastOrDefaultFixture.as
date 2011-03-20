package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class LastOrDefaultFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.lastOrDefault();
		}
		
		[Test]
		public function returns_last_value_and_completes() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.last();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(3);
			manObs.onCompleted();
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function returns_default_if_no_values() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.lastOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onCompleted();
			
			Assert.assertFalse(stats.errorCalled);
			Assert.assertTrue(stats.completedCalled);
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertNull(stats.nextValues[0]);
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
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(1, stats.completedCalled);
			Assert.assertFalse(stats.errorCalled);
		}
	}
}