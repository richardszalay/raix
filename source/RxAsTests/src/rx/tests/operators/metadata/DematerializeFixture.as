package rx.tests.operators.metadata
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class DematerializeFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.materialize().dematerialize(source.valueClass);
		}
		
		[Test]
		public function original_values_are_preserved() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize().dematerialize(int);
			
			var observer : StatsObserver = new StatsObserver();
			obs.subscribeWith(observer);
			
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onCompleted();
			
			Assert.assertEquals(2, observer.nextCount);
			Assert.assertEquals(0, observer.nextValues[0]);
			Assert.assertEquals(1, observer.nextValues[1]);
		}
		
		[Test]
		public function completed_does_not_raise_next() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize().dematerialize(int);
			
			var observer : StatsObserver = new StatsObserver();
			obs.subscribeWith(observer);
			
			manObs.onCompleted();
			
			Assert.assertFalse(observer.nextCalled);
			Assert.assertTrue(observer.completedCalled);
		}
		
		[Test]
		public function error_raises_error() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize().dematerialize(int);
			
			var observer : StatsObserver = new StatsObserver();
			obs.subscribeWith(observer);
			
			var err : Error = new Error();
			manObs.onError(err);
			
			Assert.assertTrue(observer.errorCalled);
			Assert.assertStrictlyEquals(err, observer.error);
		}
		
		[Test]
		public function error_does_not_raise_next() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize().dematerialize(int);
			
			var observer : StatsObserver = new StatsObserver();
			obs.subscribeWith(observer);
			
			manObs.onError(new Error());
			
			Assert.assertFalse(observer.nextCalled);
		}
		
		[Test]
		public function error_does_not_raise_completed() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize().dematerialize(int);
			
			var observer : StatsObserver = new StatsObserver();
			obs.subscribeWith(observer);
			
			manObs.onError(new Error());
			
			Assert.assertFalse(observer.completedCalled);
		}
		
		[Test(expects="ArgumentError")]
		public function error_is_thrown_if_source_is_not_notification() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.dematerialize(int);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.select(Boolean, function(pl:uint) : Boolean
			{
				return true;
			});
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}