package raix.reactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class AverageFixture
	{
		[Test]
        public function returns_one_value_after_completion() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.range(0, 5)
                .average()
                .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function raises_error_on_empty_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.empty()
                .average()
                .subscribeWith(stats);

            Assert.assertEquals(0, stats.nextCount);
            Assert.assertFalse(stats.completedCalled);
            Assert.assertTrue(stats.errorCalled);
        }
	}
}