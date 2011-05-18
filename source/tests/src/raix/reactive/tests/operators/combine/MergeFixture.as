package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.testing.HotObservable;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	
	[TestCase]
	public class MergeFixture
	{
		private var scheduler : TestScheduler;
        private var sources : Array;

        [Before]
        public function setUp() : void
        {
            scheduler = new TestScheduler();

            var sourceA : HotObservable = scheduler.createHotObservable([
                new Recorded(5, new OnNext(0)),
                new Recorded(25, new OnNext(1)),
                new Recorded(45, new OnNext(2)),
                new Recorded(65, new OnNext(3)),
                new Recorded(85, new OnNext(4)),
                new Recorded(85, new OnCompleted())
                ]);

            var sourceB : HotObservable = scheduler.createHotObservable([
                new Recorded(10, new OnNext(10)),
                new Recorded(30, new OnNext(11)),
                new Recorded(50, new OnNext(12)),
                new Recorded(70, new OnNext(13)),
                new Recorded(90, new OnNext(14)),
                new Recorded(90, new OnCompleted())
                ]);

            var sourceC : HotObservable = scheduler.createHotObservable([
                new Recorded(15, new OnNext(20)),
                new Recorded(35, new OnNext(21)),
                new Recorded(55, new OnNext(22)),
                new Recorded(75, new OnNext(23)),
                new Recorded(95, new OnNext(24)),
                new Recorded(95, new OnCompleted())
                ]);

            sources = [ sourceA, sourceB, sourceC ];
        }

        [Test]
        public function concurrent_messages_are_merged() : void
        {
            var observer : MockObserver = new MockObserver(scheduler);

            Observable.merge(toObservable(sources), 2)
                .subscribeWith(observer);

            scheduler.run();

            observer.assertTimings([
                new Recorded(5, new OnNext(0)),
                new Recorded(10, new OnNext(10)),
                new Recorded(25, new OnNext(1)),
                new Recorded(30, new OnNext(11)),
                new Recorded(45, new OnNext(2)),
                new Recorded(50, new OnNext(12)),
                new Recorded(65, new OnNext(3)),
                new Recorded(70, new OnNext(13)),
                new Recorded(85, new OnNext(4)), // sourceA completes, sourceC subscribes
                new Recorded(90, new OnNext(14)), 
                new Recorded(95, new OnNext(24)),
                new Recorded(95, new OnCompleted())
        	], Assert.fail);
        }

        [Test]
        public function queued_streams_are_subscribed_to_when_a_merged_stream_completes() : void
        {
            var observer : MockObserver = new MockObserver(scheduler);

            Observable.merge(toObservable(sources), 2)
                .subscribeWith(observer);

            scheduler.run();

            Assert.assertEquals(85, sources[2].subscriptions[0].subscribe);
        }

        [Test]
        public function all_streams_are_merged_if_no_concurrent_value_is_supplied() : void
        {
            var observer : MockObserver = new MockObserver(scheduler);

            Observable.merge(toObservable(sources))
                .subscribeWith(observer);

            scheduler.run();

            observer.assertTimings([
                new Recorded(5, new OnNext(0)),
                new Recorded(10, new OnNext(10)),
                new Recorded(15, new OnNext(20)),
                new Recorded(25, new OnNext(1)),
                new Recorded(30, new OnNext(11)),
                new Recorded(35, new OnNext(21)),
                new Recorded(45, new OnNext(2)),
                new Recorded(50, new OnNext(12)),
                new Recorded(55, new OnNext(22)),
                new Recorded(65, new OnNext(3)),
                new Recorded(70, new OnNext(13)),
                new Recorded(75, new OnNext(23)),
                new Recorded(85, new OnNext(4)),
                new Recorded(90, new OnNext(14)),
                new Recorded(95, new OnNext(24)),
                new Recorded(95, new OnCompleted())
            ], Assert.fail);
        }
	}
}