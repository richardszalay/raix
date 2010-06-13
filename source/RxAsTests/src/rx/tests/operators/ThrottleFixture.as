package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class ThrottleFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.throttle(0);
		}
		
		[Test]
		public function scheduler_is_used_to_reset_throttle() : void 
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            scheduler.now = new Date();

            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            subject.throttle(1000, scheduler).subscribe(stats);

            subject.onNext(0);
            subject.onNext(1);

            scheduler.now = new Date(scheduler.now.time + 1000);

            scheduler.runNext();
            scheduler.runNext();

            subject.onNext(2);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals(1, scheduler.queueSize);
        }

		[Test]
        public function exact_time_is_not_allowed() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject(int);

            var stats : StatsObserver = new StatsObserver();

            scheduler.now = new Date();

            subject
                .throttle(1000, scheduler)
                .subscribe(stats);
            
            subject.onNext(0);

            scheduler.now = new Date(scheduler.now.time + 5001);
            subject.onNext(1);

            Assert.assertEquals(1, stats.nextCount);
        }

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.throttle(5);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}