package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.Observable;
	import rx.tests.mocks.StatsObserver; 
	
	public class IfElseFixture
	{
		[Test]
        public function true_sequence_is_used_when_predicate_returns_true() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.ifElse(int, function():Boolean { return true; },
                Observable.returnValue(int, 1),
                Observable.returnValue(int, 2)
                )
                .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function false_sequence_is_used_when_predicate_returns_false() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.ifElse(int, function():Boolean { return false; },
                Observable.returnValue(int, 1),
                Observable.returnValue(int, 2)
                )
                .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function error_is_called_when_predicate_throws_exception() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var exception : Error = new ArgumentError();

            Observable.ifElse(int, function():Boolean { throw exception; },
                Observable.returnValue(int, 1),
                Observable.returnValue(int, 2)
                )
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertEquals(exception, stats.error);
        }
	}
}