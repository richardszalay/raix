package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.AssertEx;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class JoinFixture
	{
		private var stats : StatsObserver;

        private var left : Subject;
        private var right : Subject;

        private var leftWindows : Array = new Array();
        private var rightWindows : Array = new Array();

        private var leftValueAction : Function;
        private var rightValueAction : Function;
        private var combineAction : Function;

        private var subscription : ICancelable;
		
		[Before]
		public function setup() : void
		{
			stats = new StatsObserver();

            left = new Subject();
            right = new Subject();

            leftWindows = new Array(); // .<Subject>
            rightWindows = new Array(); // .<Subject>

            leftValueAction = rightValueAction = function():void{};

            combineAction = function(l:int, r:int) : String
            {
            	return l + "," + r;
            };

            subscription = left.join(right,
                function(leftVal:int) : IObservable
                    {
                        leftValueAction();
                        var leftWindow : Subject = new Subject();
                        leftWindows.push(leftWindow);
                        return leftWindow;
                    },
                function(rightVal:int) : IObservable 
                    {
                        rightValueAction();
                        var rightWindow : Subject = new Subject();
                        rightWindows.push(rightWindow);
                        return rightWindow;
                    },
                function(l:int, r:int) : String
				{
					return combineAction(l,r)
				})
                .subscribeWith(stats);
		}
		
		[Test]
        public function values_are_emitted_during_open_windows() : void
        {
            left.onNext(0);
            right.onNext(0);
            right.onNext(1);

            left.onNext(1);
            right.onNext(2);

            AssertEx.assertArrayEquals(
                ["0,0","0,1","1,0","1,1","0,2","1,2"],
            	stats.nextValues);
        }

        [Test]
        public function values_are_not_emitted_when_window_completes() : void
        {
            left.onNext(0);
            right.onNext(1);
            right.onNext(2);

            leftWindows[0].onCompleted();
            rightWindows[0].onCompleted();

            left.onNext(1);
            right.onNext(3);

            AssertEx.assertArrayEquals(
                ["0,1","0,2","1,2","1,3"],
            	stats.nextValues);
        }

        [Test]
        public function emitting_a_value_from_window_closes_window() : void
        {
            left.onNext(0);
            right.onNext(1);
            right.onNext(2);

            leftWindows[0].onNext(new Unit());
            rightWindows[0].onNext(new Unit());

            left.onNext(1);
            right.onNext(3);

            AssertEx.assertArrayEquals(
            	["0,1","0,2","1,2","1,3"],
            	stats.nextValues);
        }

        [Test]
        public function throwing_an_exception_from_selector_calls_on_error() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            var exception : Error = new Error("Test");

            combineAction = function(l:int,r:int):void { throw exception; };

            left.onNext(2);

            AssertEx.assertArrayEquals(
                ["0,0","1,0","0,1","1,1"],
            	stats.nextValues);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertStrictlyEquals(exception, stats.error);
        }

        [Test]
        public function throwing_an_exception_from_selector_unsubscribes_from_sources() : void
        {
            subscription.cancel();

            Assert.assertFalse(left.hasSubscriptions);
            Assert.assertFalse(right.hasSubscriptions);
        }

        [Test]
        public function cancellation_unsubscribes_from_all_windows() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            subscription.cancel();

            AssertEx.assertArrayEquals(
                [false, false],
                [leftWindows[0].hasSubscriptions, leftWindows[1].hasSubscriptions],
                "Left window not unsubscribed from");

            AssertEx.assertArrayEquals(
                [false, false],
                [rightWindows[0].hasSubscriptions, rightWindows[1].hasSubscriptions],
                "Right window not unsubscribed from");
        }

        [Test]
        public function throwing_an_exception_from_left_value_action_calls_on_error() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            var exception : Error = new Error("Test");
            leftValueAction = function():void  { throw exception; };
            left.onNext(2);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertStrictlyEquals(exception, stats.error);
        }

        [Test]
        public function throwing_an_exception_from_right_value_action_calls_on_error() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            var exception : Error = new Error("Test");
            rightValueAction = function():void { throw exception; };
            right.onNext(2);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertStrictlyEquals(exception, stats.error);
        }

        [Test]
        public function exception_from_left_window_action_calls_on_error() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            var exception : Error = new Error("Test");
            leftWindows[0].onError(exception);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertStrictlyEquals(exception, stats.error);
        }

        [Test]
        public function exception_from_right_window_action_calls_on_error() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onNext(1);
            right.onNext(1);

            var exception : Error = new Error("Test");
            rightWindows[0].onError(exception);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertStrictlyEquals(exception, stats.error);
        }

        [Test]
        public function completes_when_last_left_window_closes_and_left_source_is_complete() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onCompleted();
            Assert.assertFalse(stats.completedCalled);

            leftWindows[0].onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function completes_when_left_source_completes_and_no_left_windows_are_open() : void
        {
            left.onNext(0);
            right.onNext(0);

            leftWindows[0].onCompleted(); 
            Assert.assertFalse(stats.completedCalled);

            left.onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function completes_when_last_right_window_closes_and_right_source_is_complete() : void
        {
            left.onNext(0);
            right.onNext(0);

            right.onCompleted();
            Assert.assertFalse(stats.completedCalled);

            rightWindows[0].onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function completes_when_right_source_completes_and_no_right_windows_are_open() : void
        {
            left.onNext(0);
            right.onNext(0);

            left.onCompleted();
            Assert.assertFalse(stats.completedCalled);

            leftWindows[0].onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }

	}
}