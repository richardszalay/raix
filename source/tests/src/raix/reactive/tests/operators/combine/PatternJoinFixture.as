package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class PatternJoinFixture
	{
		[Test]
        public function combines_values() : void
        {
            var subjectA : IObservable = Observable.range(0, 2);
            var subjectB : IObservable = Observable.range(10, 2);

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })
                ])
                .subscribeWith(stats);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals("0,10", stats.nextValues[0]);
            Assert.assertEquals("1,11", stats.nextValues[1]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function matches_values_in_order_when_sent_out_of_order() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })
                ])
                .subscribeWith(stats);

            subjectA.onNext(0);
            subjectA.onNext(1);
            subjectA.onCompleted();

            subjectB.onNext(10);
            subjectB.onNext(11);
            subjectB.onCompleted();

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals("0,10", stats.nextValues[0]);
            Assert.assertEquals("1,11", stats.nextValues[1]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function unpartners_values_are_ignored() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })
                ])
                .subscribeWith(stats);

            subjectA.onNext(0);
            subjectA.onNext(1);
            subjectA.onCompleted();

            subjectB.onNext(10);
            subjectB.onCompleted();

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("0,10", stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function merges_multiple_joins() : void
        {
            var subjectA : IObservable = Observable.range(0, 2);
            var subjectB : IObservable = Observable.range(2, 2);
            var subjectC : IObservable = Observable.range(4, 2);
            var subjectD : IObservable = Observable.range(6, 2);

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); }),
                subjectC.and(subjectD).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })                
                ])
                .subscribeWith(stats);

            Assert.assertEquals(4, stats.nextCount);
            Assert.assertEquals("0,2", stats.nextValues[0]);
            Assert.assertEquals("4,6", stats.nextValues[1]);
            Assert.assertEquals("1,3", stats.nextValues[2]); 
            Assert.assertEquals("5,7", stats.nextValues[3]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function raises_error_when_subscription_is_repeated_within_pattern() : void
        {
            var subjectA : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectA).then(String, function(x:int,y:int):String { return null; })
                ])
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertTrue(stats.error is ArgumentError);
        }

        [Test]
        public function subscribes_once_when_subscription_is_repeated_within_join() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                subjectA.and(subjectB).then(String, function(x:int,y:int):String { return null; }),
                subjectB.and(subjectA).then(String, function(x:int,y:int):String { return null; })
                ])
                .subscribeWith(stats);

            Assert.assertEquals(1, subjectA.subscriptionCount);
            Assert.assertEquals(1, subjectB.subscriptionCount);
        }

        [Test]
        public function merges_multiple_joins_that_share_sources() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();
            var subjectC : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                    subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); }),
                    subjectA.and(subjectC).then(String, function(x:int,y:int):String { return x.toString() + "." + y.toString(); })
                ])
                .subscribeWith(stats);

            subjectA.onNext(0);
            subjectC.onNext(1);

            subjectA.onNext(2);
            subjectB.onNext(3);

            Assert.assertEquals(2, stats.nextCount);
            Assert.assertEquals("0.1", stats.nextValues[0]);
            Assert.assertEquals("2,3", stats.nextValues[1]);
        }

        [Test]
        public function errors_cause_all_subscriptions_to_be_removed() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();
            var subjectC : Subject = new Subject();
            var subjectD : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                    subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); }),
                    subjectC.and(subjectD).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })
                ])
                .subscribeWith(stats);

            Assert.assertEquals(1, subjectA.subscriptionCount);
            Assert.assertEquals(1, subjectB.subscriptionCount);
            Assert.assertEquals(1, subjectC.subscriptionCount);
            Assert.assertEquals(1, subjectD.subscriptionCount);

            subjectA.onError(new Error());

            Assert.assertEquals(0, subjectA.subscriptionCount);
            Assert.assertEquals(0, subjectB.subscriptionCount);
            Assert.assertEquals(0, subjectC.subscriptionCount);
            Assert.assertEquals(0, subjectD.subscriptionCount);
        }

        [Test]
        public function complete_does_not_unsubscribe_from_other_subjects() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();
            var subjectC : Subject = new Subject();
            var subjectD : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            Observable.when(String, [
                    subjectA.and(subjectB).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); }),
                    subjectC.and(subjectD).then(String, function(x:int,y:int):String { return x.toString() + "," + y.toString(); })
                ])
                .subscribeWith(stats);

            Assert.assertEquals(1, subjectA.subscriptionCount);
            Assert.assertEquals(1, subjectB.subscriptionCount);
            Assert.assertEquals(1, subjectC.subscriptionCount);
            Assert.assertEquals(1, subjectD.subscriptionCount);

            subjectA.onCompleted();

            Assert.assertEquals(0, subjectA.subscriptionCount);
            Assert.assertEquals(1, subjectB.subscriptionCount);
            Assert.assertEquals(1, subjectC.subscriptionCount);
            Assert.assertEquals(1, subjectD.subscriptionCount);
        }
	}
}