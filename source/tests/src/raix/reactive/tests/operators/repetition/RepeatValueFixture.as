package raix.reactive.tests.operators.repetition
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class RepeatValueFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.concat(Observable.empty().repeat(1));
		}
		
		[Test]
		public function repeatCount_includes_initial_subscriptions() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.repeatValue(5, 3)
				.subscribeWith(stats);
				
			Assert.assertEquals(3, stats.nextCount);
		}
		
		[Test]
		public function repeats_source_given_number_of_times() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.repeatValue(5, 3)
				.subscribeWith(stats);
				
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(5, stats.nextValues[0]);
			Assert.assertEquals(5, stats.nextValues[1]);
			Assert.assertEquals(5, stats.nextValues[2]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function does_not_overflow_the_stack() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.repeatValue(5, 500)
				.subscribeWith(stats);
		}
		
        [Test]
        public function repeat_with_no_arguments_repeats_forever() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
			Observable.repeatValue(5)
				.take(200)
				.subscribeWith(stats);

            Assert.assertEquals(200, stats.nextCount);
        }
	}
}