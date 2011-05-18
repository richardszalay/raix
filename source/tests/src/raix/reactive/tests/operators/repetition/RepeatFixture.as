package raix.reactive.tests.operators.repetition
{
	import org.flexunit.Assert;
	
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class RepeatFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.concat(Observable.empty().repeat(1));
		}
		
		[Test]
		public function repeatCount_includes_initial_subscriptions() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.value(5)
				.repeat(3)
				.subscribeWith(stats);
				
			Assert.assertEquals(3, stats.nextCount);
		}
		
		[Test]
		public function repeats_source_given_number_of_times() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.value(5)
				.repeat(3)
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
			
			Observable.value(5)
				.repeat(500)
				.subscribeWith(stats);
		}
		
		[Test]
        public function resubscribes_after_completion() : void
        {
            var subscribeCount : int = 0;

            var source : IObservable = Observable.createWithCancelable(function(obs:IObserver):ICancelable
                {
                    subscribeCount++;

                    obs.onCompleted();

                    return Cancelable.empty;
                });

            var stats : StatsObserver = new StatsObserver();
            source.repeat(2).subscribeWith(stats);

            Assert.assertEquals(2, subscribeCount);
        }

        [Test]
        public function errors_stop_repeats() : void
        {
            var subscribeCount : int = 0;

            var source : IObservable = Observable.createWithCancelable(function(obs:IObserver):ICancelable
            {
                subscribeCount++;

                obs.onError(new Error());

                return Cancelable.empty;
            });

            var stats : StatsObserver = new StatsObserver();
            source.repeat(2).subscribeWith(stats);

            Assert.assertEquals(1, subscribeCount);
            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function repeat_with_no_arguments_repeats_forever() : void
        {
            var subscribeCount : int = 0;

            var source : IObservable = Observable.createWithCancelable(function(obs:IObserver):ICancelable
            {
                if (subscribeCount < 200)
                {
                    obs.onNext(subscribeCount++);
                    obs.onCompleted();
                }

                return Cancelable.empty;
            });

            var stats : StatsObserver = new StatsObserver();
            source.repeat().subscribeWith(stats);

            Assert.assertEquals(200, subscribeCount);
            Assert.assertFalse(stats.completedCalled);
        }
	}
}