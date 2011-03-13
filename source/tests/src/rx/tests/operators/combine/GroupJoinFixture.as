package rx.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import rx.*;
	import rx.tests.AssertEx;
	import rx.tests.mocks.StatsObserver;
	
	public class GroupJoinFixture
	{
		private var groupedValues : Subject;
		private var stats : StatsObserver;

        private var left : Subject;
        private var right : Subject;

        private var leftWindows : Array = new Array();
        private var rightWindows : Array = new Array();

        private var leftValueAction : Function;
        private var rightValueAction : Function;
        private var combineAction : Function;

        private var subscription : CompositeCancelable;
		
		[Before]
		public function setup() : void
		{
			stats = new StatsObserver();

            left = new Subject(int);
            right = new Subject(int);
            
            groupedValues = new Subject(Object);

            leftWindows = new Array(); // .<Subject>
            rightWindows = new Array(); // .<Subject>

            leftValueAction = rightValueAction = function():void{};
            
            subscription = new CompositeCancelable();

            combineAction = function(l:int, r:int) : String
            {
            	return l + "," + r;
            };

            subscription.add(left.groupJoin(right,
                function(leftVal:int) : IObservable
                    {
                        leftValueAction();
                        var leftWindow : Subject = new Subject(Unit);
                        leftWindows.push(leftWindow);
                        return leftWindow;
                    },
                function(rightVal:int) : IObservable 
                    {
                        rightValueAction();
                        var rightWindow : Subject = new Subject(Unit);
                        rightWindows.push(rightWindow);
                        return rightWindow;
                    },
                Object, function(l:int, r:IObservable) : Object
				{
                    combineAction(l,r);

                    return { key:l, values:r };
                })
                .subscribeWith(groupedValues));
                
           subscription.add(groupedValues
                .mapMany(Object, function (group : Object) : IObservable
                {
                	return IObservable(group.values).map(Object, function(r:int):Object
                	{
                		return {l:group.key, r:r};
                	});
                })
                .map(String, function(tuple : Object) : String { return tuple.l+","+tuple.r; })
                .subscribeWith(stats));
		}
		
		[Test]
        public function values_can_be_emitted_from_the_right_first() : void
        {
            right.onNext(0);
            left.onNext(0);

            left.onNext(1);
            right.onNext(1);

            AssertEx.assertArrayEquals([
                "0,0","1,0","0,1","1,1"
            ], stats.nextValues);
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
                             // !
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

            rightWindows[0].onCompleted();
            Assert.assertFalse(stats.completedCalled);

            right.onCompleted();
            Assert.assertTrue(stats.completedCalled);
        }

	}
}