package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class CombineLatestFixture
	{
		[Test]
        public function subscribes_to_both_sources() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            Assert.assertEquals(1, subjectA.subscriptionCount);
            Assert.assertEquals(1, subjectB.subscriptionCount);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function emits_combinations_of_the_latest_values() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onNext(1);
            subjectB.onNext(2);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("1,2", stats.nextValues[0]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function reuses_values() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onNext(1);
            subjectB.onNext(2);
            subjectA.onNext(3);
            subjectB.onNext(4);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals("1,2", stats.nextValues[0]);
            Assert.assertEquals("3,2", stats.nextValues[1]);
            Assert.assertEquals("3,4", stats.nextValues[2]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function only_uses_latest_value() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onNext(1);
            subjectA.onNext(2);
            subjectB.onNext(3);
            subjectB.onNext(4);
            subjectA.onNext(5);
            subjectA.onNext(6);

            Assert.assertEquals(4, stats.nextCount);
            Assert.assertEquals("2,3", stats.nextValues[0]);
            Assert.assertEquals("2,4", stats.nextValues[1]);
            Assert.assertEquals("5,4", stats.nextValues[2]);
            Assert.assertEquals("6,4", stats.nextValues[3]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function last_value_is_still_used_after_complete() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onNext(1);
            subjectA.onCompleted();

            subjectB.onNext(2);
            subjectB.onNext(3);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals("1,2", stats.nextValues[0]);
            Assert.assertEquals("1,3", stats.nextValues[1]);
            Assert.assertFalse(stats.completedCalled);
        }

        [Test]
        public function complete_is_fired_when_both_sequences_complete() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onNext(1);
            subjectA.onCompleted();

            subjectB.onNext(2);
            subjectB.onCompleted();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("1,2", stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function error_is_fired_on_error_from_either_source() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onError(new Error());

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function unsubscribes_from_both_sequences_when_complete() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onCompleted();
            subjectB.onCompleted();

            Assert.assertEquals(0, subjectA.subscriptionCount);
            Assert.assertEquals(0, subjectB.subscriptionCount);
        }

        [Test]
        public function unsubscribes_from_both_sequences_on_error() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            subjectA.onError(new Error());

            Assert.assertEquals(0, subjectA.subscriptionCount);
            Assert.assertEquals(0, subjectB.subscriptionCount);
        }
        
        [Test]
        public function handles_synchronous_sources() : void
        {
            var subjectA : IObservable = Observable.range(0, 2);
            var subjectB : IObservable = Observable.range(2, 2);

            var stats : StatsObserver = new StatsObserver();

            subjectA.combineLatest(subjectB, function (a:int, b:int) : String { return a.toString() + "," + b.toString(); })
                .subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals("0,2", stats.nextValues[0]);
            Assert.assertEquals("1,2", stats.nextValues[1]);
            Assert.assertEquals("1,3", stats.nextValues[2]);
        }
	}
}