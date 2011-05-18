package raix.reactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ScanFixture
	{
		[Test]
        public function outputs_one_value_for_each_input() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.range(0, 5)
                .scan(function(x:int,y:int):int { return x + y; })
                .subscribeWith(stats);

            Assert.assertEquals(5, stats.nextCount);
            Assert.assertEquals(0, stats.nextValues[0]);
            Assert.assertEquals(1, stats.nextValues[1]);
            Assert.assertEquals(3, stats.nextValues[2]);
            Assert.assertEquals(6, stats.nextValues[3]);
            Assert.assertEquals(10, stats.nextValues[4]);
        }

        [Test]
        public function outputs_accumulator_type_if_different() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var start : Date = new Date();

            Observable.range(0, 5)
                .scan(function(x:Date,y:int):Date { return new Date(x.time + y); }, start, true)
                .subscribeWith(stats);

            Assert.assertEquals(5, stats.nextCount);
            Assert.assertEquals(start.time + 0, stats.nextValues[0].time);
            Assert.assertEquals(start.time + 1, stats.nextValues[1].time);
            Assert.assertEquals(start.time + 3, stats.nextValues[2].time);
            Assert.assertEquals(start.time + 6, stats.nextValues[3].time);
            Assert.assertEquals(start.time + 10, stats.nextValues[4].time);
        }

        [Test]
        public function calls_accumulator_for_first_value_when_initial_value_supplied() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var accumulatorValues : Array = new Array();

            var start : Date = new Date();

            Observable.range(0, 5)
                .scan(function(x:Date,y:int):Date { accumulatorValues.push(y); return x; }, start, true)
                .subscribeWith(stats);

            Assert.assertEquals(0, accumulatorValues[0]);
        }

        [Test]
        public function does_not_call_accumulator_for_first_value_initial_value_not_supplied() : void
        {
            var stats : StatsObserver = new StatsObserver();

            var accumulatorValues : Array = new Array();

            Observable.range(0, 5)
                .scan(function(x:int,y:int):int { accumulatorValues.push(y); return x+y; })
                .subscribeWith(stats);

            Assert.assertEquals(1, accumulatorValues[0]);
        }
        
        [Test]
        public function does_not_error_on_empty_source() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.empty()
                .scan(function(x:int,y:int):int { return x + y; })
                .subscribeWith(stats);

            Assert.assertFalse(stats.errorCalled);
            Assert.assertTrue(stats.completedCalled);
        }

	}
}