package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	public class SingleOrDefaultFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.singleOrDefault();
		}
		
		[Test]
		public function returns_single_value_after_completion() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.singleOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(1);
			
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertFalse(stats.completedCalled);
			
			manObs.onCompleted();
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function returns_default_if_no_values() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.singleOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onCompleted();
			
			Assert.assertEquals(1, stats.nextCalled);
			Assert.assertFalse(stats.errorCalled);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function returns_error_if_multiple_values() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.singleOrDefault();
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(1);
			
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
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
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			manObs.onNext(new Object());
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertTrue(stats.completedCalled);
			Assert.assertFalse(stats.errorCalled);
		}

	}
}