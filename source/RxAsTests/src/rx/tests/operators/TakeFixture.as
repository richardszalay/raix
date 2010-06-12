package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class TakeFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.take(3);
		}
		
		[Test]
		public function complete_is_called_after_specified_values_taken() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.take(3);
			
			var nextCount : uint = 0;
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { nextCount++; },
				function():void { completeCalled = true; }	
			);
			
			manObs.onNext(0);
			Assert.assertEquals(1, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(2, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(3, nextCount);
			Assert.assertTrue(completeCalled);
		}

		[Test]
        public function scheduler_is_not_used_when_count_great_than_zero() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            subject.take(3, scheduler).subscribe(stats);

            subject.onNext(0);
            subject.onNext(1);
            subject.onNext(2);
            
            Assert.assertEquals(0, scheduler.queueSize);
        }

        [Test]
        public function scheduler_is_used_for_completion_when_take_is_zero() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var stats : StatsObserver = new StatsObserver();

            new Subject(int).take(0, scheduler).subscribe(stats);

            Assert.assertFalse(stats.completedCalled);

            scheduler.runNext();

            Assert.assertTrue(stats.completedCalled);
        }

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.take(3);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}