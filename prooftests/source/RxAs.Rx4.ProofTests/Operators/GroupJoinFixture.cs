using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Disposables;
using System.Diagnostics;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class GroupJoinFixture
    {
        StatsSubject<Tuple<int, IObservable<int>>> groupedValues;

        StatsSubject<int> left;
        StatsSubject<int> right;

        List<StatsSubject<Unit>> leftWindows;
        List<StatsSubject<Unit>> rightWindows;

        Action leftValueAction, rightValueAction;
        Action<int, IObservable<int>> combineAction;

        StatsObserver<string> stats;

        CompositeDisposable subscription;

        [SetUp]
        public void SetUp()
        {
            groupedValues = new StatsSubject<Tuple<int, IObservable<int>>>();
            stats = new StatsObserver<string>();

            left = new StatsSubject<int>();
            right = new StatsSubject<int>();

            leftWindows = new List<StatsSubject<Unit>>();
            rightWindows = new List<StatsSubject<Unit>>();

            leftValueAction = rightValueAction = () => { };

            combineAction = (l, r) => {};

            subscription = new CompositeDisposable();

            subscription.Add(left.GroupJoin(right,
                leftVal =>
                {
                    leftValueAction();
                    var leftWindow = new StatsSubject<Unit>();
                    leftWindows.Add(leftWindow);
                    return leftWindow;
                },
                rightVal =>
                {
                    rightValueAction();
                    var rightWindow = new StatsSubject<Unit>();
                    rightWindows.Add(rightWindow);
                    return rightWindow;
                },
                (l, r) =>
                {
                    combineAction(l,r);

                    return new Tuple<int, IObservable<int>>(l, r);
                })
                .Subscribe(groupedValues));

            subscription.Add(groupedValues
                .SelectMany(input => input.Item2.Select(r => new Tuple<int, int>(input.Item1, r)))
                .Select(t => String.Format("{0},{1}", t.Item1, t.Item2))
                .Subscribe(stats));
        }

        [Test]
        public void values_are_emitted_during_open_windows()
        {
            left.OnNext(0);
            right.OnNext(0);
            right.OnNext(1);

            left.OnNext(1);
            right.OnNext(2);

            Assert.AreEqual(new string[]
            {
                "0,0","0,1","1,0","1,1","0,2","1,2"
            }, stats.NextValues);
        }

        [Test]
        public void values_are_not_emitted_when_window_completes()
        {
            left.OnNext(0);
            right.OnNext(1);
            right.OnNext(2);

            leftWindows[0].OnCompleted();
            rightWindows[0].OnCompleted();

            left.OnNext(1);
            right.OnNext(3);

            Assert.AreEqual(new string[]
            {
                "0,1","0,2","1,2","1,3"
            }, stats.NextValues);
        }

        [Test]
        public void emitting_a_value_from_window_closes_window()
        {
            left.OnNext(0);
            right.OnNext(1);
            right.OnNext(2);

            leftWindows[0].OnNext(new Unit());
            rightWindows[0].OnNext(new Unit());

            left.OnNext(1);
            right.OnNext(3);

            Assert.AreEqual(new string[]
            {
                "0,1","0,2","1,2","1,3"
            }, stats.NextValues);
        }

        [Test]
        public void throwing_an_exception_from_selector_calls_on_error()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);

            Exception exception = new Exception("Test");

            combineAction = (l, r) => { throw exception; };

            left.OnNext(2);

            Assert.AreEqual(new string[]
            {
                "0,0","1,0","0,1","1,1"
            }, stats.NextValues);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreSame(exception, stats.Error);
        }

        [Test]
        public void throwing_an_exception_from_selector_unsubscribes_from_sources()
        {
            subscription.Dispose();

            Assert.IsFalse(left.HasSubscriptions);
            Assert.IsFalse(right.HasSubscriptions);
        }

        [Test]
        public void cancellation_unsubscribes_from_all_windows()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);



            subscription.Dispose();

            Assert.AreEqual(
                leftWindows.Select(_ => false).ToArray(),
                leftWindows.Select(w => w.HasSubscriptions).ToArray(),
                "Left window not unsubscribed from");

            Assert.AreEqual(
                rightWindows.Select(_ => false).ToArray(),
                rightWindows.Select(w => w.HasSubscriptions).ToArray(),
                "Right window not unsubscribed from");
        }

        [Test]
        public void throwing_an_exception_from_left_value_action_calls_on_error()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);

            Exception exception = new Exception("Test");
            leftValueAction = () => { throw exception; };
            left.OnNext(2);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreSame(exception, stats.Error);
        }

        [Test]
        public void throwing_an_exception_from_right_value_action_calls_on_error()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);

            Exception exception = new Exception("Test");
            rightValueAction = () => { throw exception; };
            right.OnNext(2);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreSame(exception, stats.Error);
        }

        [Test]
        public void exception_from_left_window_action_calls_on_error()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);

            Exception exception = new Exception("Test");
            leftWindows[0].OnError(exception);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreSame(exception, stats.Error);
        }

        [Test]
        public void exception_from_right_window_action_calls_on_error()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnNext(1);
            right.OnNext(1);

            Exception exception = new Exception("Test");
            rightWindows[0].OnError(exception);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.AreSame(exception, stats.Error);
        }

        [Test]
        public void completes_when_last_left_window_closes_and_left_source_is_complete()
        {
            left.OnNext(0);
            right.OnNext(0);

            left.OnCompleted();
            Assert.IsFalse(stats.CompletedCalled);

            leftWindows[0].OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void completes_when_left_source_completes_and_no_left_windows_are_open()
        {
            left.OnNext(0);
            right.OnNext(0);

            leftWindows[0].OnCompleted(); 
            Assert.IsFalse(stats.CompletedCalled);

            left.OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void completes_when_last_right_window_closes_and_right_source_is_complete()
        {
            left.OnNext(0);
            right.OnNext(0);

            right.OnCompleted();
            Assert.IsFalse(stats.CompletedCalled);

            rightWindows[0].OnCompleted();
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void completes_when_right_source_completes_and_no_right_windows_are_open()
        {
            left.OnNext(0);
            right.OnNext(0);

            rightWindows[0].OnCompleted();
            Assert.IsFalse(stats.CompletedCalled);

            right.OnCompleted();
            Assert.IsTrue(stats.CompletedCalled); 
        }

        [Test]
        public void GroupJoinBugRepro()
        {
            Subject<int> left = new Subject<int>();
            Subject<int> right = new Subject<int>();

            Subject<Tuple<int,IObservable<int>>> groups = 
                new Subject<Tuple<int,IObservable<int>>>();

            var groupJoinSubscription = left.GroupJoin(right,
                l => Observable.Never<Unit>().Finally(() => Debug.WriteLine("Left window subscription terminated")),
                r => Observable.Never<Unit>().Finally(() => Debug.WriteLine("Right window subscription terminated")),
                (l, rs) => new Tuple<int, IObservable<int>>(l, rs)
                )
                .Subscribe(groups);


            var groupsSubscription = groups
                .SelectMany(g => g.Item2.Select(r => new Tuple<int, int>(g.Item1, r)))
                .Select(t => String.Format("{0},{1}", t.Item1, t.Item2))
                .Subscribe(x => Debug.WriteLine(x));

            left.OnNext(0);
            left.OnNext(1);

            right.OnNext(2);

            Debug.WriteLine("Cancelling GroupJoin");
            groupJoinSubscription.Dispose();

            Debug.WriteLine("Cancelling Groups");
            groupsSubscription.Dispose();
        }
    }
}
