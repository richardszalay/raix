package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.*;
	import rx.tests.mocks.StatsObserver;
	
	public class SumFixture
	{
		[Test]
        public function returns_one_value_after_completion() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.range(0, 5)
                .sum()
                .subscribe(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(10, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }

        [Test]
        public function returns_zero_on_empty_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.empty()
                .sum()
                .subscribe(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(0, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
        }
	}
}