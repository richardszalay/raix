package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class ThrottleFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.throttle(0);
		}
		
		[Test]
		public function scheduler_is_used_to_determine_time() : void 
        {
        	// TODO: This is not how the Rx throttle works,
        	// the rxas imlpementation should be brought in line to match Rx
        	
            var scheduler : ManualScheduler = new ManualScheduler();

            scheduler.now = new Date();

            var subject : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subject.throttle(1000, scheduler).subscribeWith(stats);

            subject.onNext(0);
            
            scheduler.now = new Date(scheduler.now.time + 1001);
            subject.onNext(1);

            subject.onNext(2);

            Assert.assertEquals(2, stats.nextCount);
        }

		[Test]
        public function exact_time_is_not_allowed() : void
        {
            var scheduler : ManualScheduler = new ManualScheduler();

            var subject : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            scheduler.now = new Date();

            subject
                .throttle(1000, scheduler)
                .subscribeWith(stats);
            
            subject.onNext(0);

            scheduler.now = new Date(scheduler.now.time + 1000);
            subject.onNext(1);

            Assert.assertEquals(1, stats.nextCount);
        }

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = manObs.throttle(5);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}