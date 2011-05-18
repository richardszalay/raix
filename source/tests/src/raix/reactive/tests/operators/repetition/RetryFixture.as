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
	
	public class RetryFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.concat(Observable.empty().retry(1));
		}
		
		[Test]
		public function repeats_source_given_number_of_times() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.value(5).concat(Observable.error(new Error()))
				.retry(3)
				.subscribeWith(stats);

			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(5, stats.nextValues[0]);
			Assert.assertEquals(5, stats.nextValues[1]);
			Assert.assertEquals(5, stats.nextValues[2]);
			Assert.assertTrue(stats.errorCalled);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function does_not_overflow_the_stack() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.value(5).concat(Observable.error(new Error()))
				.retry(500)
				.subscribeWith(stats);
		}
		
		[Test]
        public function resubscribes_after_completion() : void
        {
            var subscribeCount : int = 0;

            var source : IObservable = Observable.createWithCancelable(function(obs:IObserver):ICancelable
                {
                    subscribeCount++;

                    obs.onError(new Error());

                    return Cancelable.empty;
                });

            var stats : StatsObserver = new StatsObserver();
            source.retry(2).subscribeWith(stats);

            Assert.assertEquals(2, subscribeCount);
        }

        [Test]
        public function complete_stop_repeats() : void
        {
            var subscribeCount : int = 0;

            var source : IObservable = Observable.createWithCancelable(function(obs:IObserver):ICancelable
            {
                subscribeCount++;

                obs.onCompleted();

                return Cancelable.empty;
            });

            var stats : StatsObserver = new StatsObserver();
            source.retry(2).subscribeWith(stats);

            Assert.assertEquals(1, subscribeCount);
            Assert.assertTrue(stats.completedCalled);
            Assert.assertFalse(stats.errorCalled);
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
                    obs.onError(new Error());
                }

                return Cancelable.empty;
            });

            var stats : StatsObserver = new StatsObserver();
            source.retry().subscribeWith(stats);

            Assert.assertEquals(200, subscribeCount);
            Assert.assertFalse(stats.completedCalled);
        }
	}
}