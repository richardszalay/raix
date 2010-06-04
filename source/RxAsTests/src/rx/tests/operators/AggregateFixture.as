package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.*;
	import rx.tests.mocks.StatsObserver;
	
	public class AggregateFixture
	{
		[Test]
        public function outputs_one_value_after_completion() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.range(0, 5)
                .aggregate(function(x:int,y:int):int { return x + y; })
                .subscribe(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(10, stats.nextValues[0]);
        }

        [Test]
        public function outputs_accumulator_type_if_different() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var start : Date = new Date();

            Observable.range(0, 5)
                .aggregate(function(x:Date,y:int):Date { return new Date(x.time + y); }, Date, start)
                .subscribe(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(start.time + 10, stats.nextValues[0].time);
        }

        [Test]
        public function calls_accumulator_for_first_value_when_initial_value_supplied() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var accumulatorValues : Array = new Array();

            var start : Date = new Date();

            Observable.range(0, 5)
                .aggregate(function(x:Date,y:int):Date { accumulatorValues.push(y); return x; }, Date, start)
                .subscribe(stats);

            Assert.assertEquals(0, accumulatorValues[0]);
        }

        [Test]
        public function does_not_call_accumulator_for_first_value_initial_value_not_supplied() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var accumulatorValues : Array = new Array();

            Observable.range(0, 5)
                .aggregate(function(x:int,y:int):int { accumulatorValues.push(y); return x+y; })
                .subscribe(stats);

            Assert.assertEquals(1, accumulatorValues[0]);
        }
        
        [Test]
        public function raises_error_on_empty_source() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
            Observable.empty(int)
                .aggregate(function(x:int,y:int):int { return x + y; })
                .subscribe(stats);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertFalse(stats.completedCalled);
        }

	}
}