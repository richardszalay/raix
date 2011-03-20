package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ForkJoinInstanceFixture
	{
		private var selector : Function = function (x:int, y:int) : String { return x.toString() + "," + y.toString(); };

        [Test]
        public function no_values_are_emitted_if_one_source_is_empty() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.empty().forkJoin(Observable.value(1), selector)
                    .subscribeWith(stats);

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function value_array_is_emitted_if_both_sources_have_one_value() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.value(1).forkJoin(Observable.value(2), selector)
                    .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("1,2", stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function last_values_are_emitted_if_both_sources_have_multiple_values() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.range(0, 2).forkJoin(Observable.range(2, 2), selector)
                    .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("1,3", stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function values_are_emitted_after_all_sequences_complete() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.forkJoin(subjectB, selector)
                    .subscribeWith(stats);

            subjectA.onNext(0);
            subjectB.onNext(1);
            subjectB.onCompleted();
            Assert.assertFalse(stats.nextCalled);

            subjectA.onCompleted();
            Assert.assertTrue(stats.nextCalled);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals("0,1", stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function sequence_completes_when_all_sequences_complete() : void
        {
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();

            var stats : StatsObserver = new StatsObserver();

            subjectA.forkJoin(subjectB, selector)
                    .subscribeWith(stats);

            subjectA.onNext(0);
            subjectB.onNext(1);
            subjectB.onCompleted();
            Assert.assertFalse(stats.completedCalled);

            subjectA.onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }
	}
}