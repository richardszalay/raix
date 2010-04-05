package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class SkipUntilFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.skipUntil(Observable.returnValue(int, 1));
		}
		
		[Test]
		public function returns_values_after_other_emits_value() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.skipUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribe(stats);
			
			primaryObs.onNext(0);
			primaryObs.onNext(1);
			primaryObs.onNext(2);
			otherObs.onNext(0);
			primaryObs.onNext(3);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(3, stats.nextValues[0]);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function complete_does_not_equate_to_value() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.skipUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribe(stats);
			
			primaryObs.onNext(0);
			primaryObs.onNext(1);
			primaryObs.onNext(2);
			otherObs.onCompleted();
			primaryObs.onNext(3);
			
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function unsubscribes_from_other_after_value() : void
		{
			var primaryObs : Subject = new Subject(int);
			var otherObs : Subject = new Subject(int);
			
			var obs : IObservable = primaryObs.skipUntil(otherObs);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribe(stats);
			
			otherObs.onNext(0);
			
			Assert.assertFalse(otherObs.hasSubscriptions);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			var obs : IObservable = manObs.skipUntil(Observable.returnValue(int, 1));
			
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}