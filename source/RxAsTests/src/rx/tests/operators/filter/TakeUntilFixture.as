package rx.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class TakeUntilFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.takeUntil(Observable.never(source.valueClass));
		}
		
		[Test]
		public function values_are_returned_until_other_observer_raises_value() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.takeUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			primaryObs.onNext(0);
			primaryObs.onNext(1);
			primaryObs.onNext(2);
			otherObs.onNext(0);
			primaryObs.onNext(3);
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertEquals(2, stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function values_are_returned_until_other_observer_completes() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.takeUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			primaryObs.onNext(0);
			primaryObs.onNext(1);
			primaryObs.onNext(2);
			otherObs.onCompleted();
			primaryObs.onNext(3);
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertEquals(2, stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function values_are_returned_until_other_observer_raises_error() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.takeUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			primaryObs.onNext(0);
			primaryObs.onNext(1);
			primaryObs.onNext(2);
			otherObs.onError(new Error());
			primaryObs.onNext(3);
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertEquals(2, stats.nextValues[2]);
			Assert.assertTrue(stats.errorCalled);
			
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.takeUntil(Observable.never(int));
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}