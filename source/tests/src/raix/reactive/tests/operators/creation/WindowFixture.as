package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.Unit;
	import raix.reactive.tests.AssertEx;
	import raix.reactive.tests.mocks.StatsObserver; 
	
    public class WindowFixture
    {
        private var source : Subject;
        private var windows : Array;

        private var windowsStats : Array;
        private var overallStats : StatsObserver;

        private var subscription : ICancelable;

        [Before]
        public function SetUp() : void
        {
            source = new Subject();
            windows = new Array();
            windowsStats = new Array();
            overallStats = new StatsObserver();

            subscription = source.window(function() : IObservable 
                {
                    var window : Subject = new Subject();

                    windows.push(window);

                    return window;
                })
                .subscribe(function(o:IObservable) : void
                {
                    var stats : StatsObserver = new StatsObserver();
                    windowsStats.push(stats);

                    o.subscribeWith(stats);
                },
                overallStats.onCompleted,
                overallStats.onError
                );
        }

        [Test]
        public function first_window_is_opened_immediately() : void
        {
            Assert.assertEquals(1, windowsStats.length);
        }

        [Test]
        public function values_within_window_are_emitted() : void
        {
            source.onNext(0);
            source.onNext(1);
            source.onNext(2);

            Assert.assertEquals(1, windowsStats.length);
            Assert.assertEquals(3, windowsStats[0].nextCount);
            AssertEx.assertArrayEquals([ 0, 1, 2 ], windowsStats[0].nextValues);
        }

        [Test]
        public function new_window_is_opened_immediately_after_last_window_closes() : void
        {
            source.onNext(0);
            source.onNext(1);

            windows[0].onNext(new Unit());

            Assert.assertEquals(2, windowsStats.length);
        }

        [Test]
        public function windows_can_be_completed_using_oncompleted() : void
        {
            source.onNext(0);
            source.onNext(1);

            windows[0].onCompleted();

            Assert.assertEquals(2, windowsStats.length);
        }

        [Test]
        public function previous_window_values_are_completed_when_new_window_opens() : void
        {
            windows[0].onCompleted();

            Assert.assertTrue(windowsStats[0].completedCalled);
        }

        [Test]
        public function source_observer_completes_when_source_completes() : void
        {
            source.onCompleted();

            Assert.assertTrue(overallStats.completedCalled);
        }

        [Test]
        public function open_window_completes_when_source_completes() : void
        {
            source.onCompleted();

            Assert.assertTrue(windowsStats[0].completedCalled);
        }

        [Test]
        public function open_window_errors_when_source_errors() : void
        {
            source.onError(new Error());

            Assert.assertTrue(windowsStats[0].errorCalled);
        }

        [Test]
        public function source_observer_errors_when_source_errors() : void
        {
            source.onError(new Error());

            Assert.assertTrue(overallStats.errorCalled);
        }

        [Test(message="Failing indeterminately")]
        public function source_observer_errors_when_open_window_errors() : void
        {
            windows[0].onError(new Error());

            Assert.assertTrue(overallStats.errorCalled);
        }

        [Test]
        public function window_observer_errors_when_open_window_errors() : void
        {
            windows[0].onError(new Error());

            Assert.assertTrue(this.windowsStats[0].errorCalled);
        }

        [Test]
        public function unsubscripes_from_open_window_when_source_subscription_is_disposed() : void
        {
            subscription.cancel();

            Assert.assertFalse(windows[0].hasSubscriptions);
        }
    }
}