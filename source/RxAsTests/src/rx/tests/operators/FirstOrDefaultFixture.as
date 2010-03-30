package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.StatsObserver;
	
	public class FirstOrDefaultFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.firstOrDefault();
		}
		
		[Test]
		public function returns_first_value_and_completes() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.firstOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribe(stats);
			
			manObs.onNext(1);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function returns_default_if_no_values() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.firstOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribe(stats);
			
			manObs.onCompleted();
			
			Assert.assertFalse(stats.errorCalled);
			Assert.assertTrue(stats.completedCalled);
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertNull(stats.nextValues[0]);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.asObservable();
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
		
		[Test]
		public override function is_normalized_for_oncompleted() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribe(stats);
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(1, stats.completedCalled);
			Assert.assertFalse(stats.errorCalled);
		}
	}
}