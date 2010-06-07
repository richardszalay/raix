using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;
using System.Diagnostics;

namespace RxAs.Rx2.ProofTests.Operators
{
    [TestFixture]
    public class JoinsFixture
    {
        [Test]
        public void combines_values()
        {
            var subjectA = Observable.Range(0, 2);
            var subjectB = Observable.Range(10, 2);

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual("0,10", stats.NextValues[0]);
            Assert.AreEqual("1,11", stats.NextValues[1]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void matches_values_in_order_when_sent_out_of_order()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            subjectA.OnNext(0);
            subjectA.OnNext(1);
            subjectA.OnCompleted();

            subjectB.OnNext(10);
            subjectB.OnNext(11);
            subjectB.OnCompleted();

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual("0,10", stats.NextValues[0]);
            Assert.AreEqual("1,11", stats.NextValues[1]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void unpartners_values_are_ignored()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            subjectA.OnNext(0);
            subjectA.OnNext(1);
            subjectA.OnCompleted();

            subjectB.OnNext(10);
            subjectB.OnCompleted();

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual("0,10", stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void merges_multiple_joins()
        {
            var subjectA = Observable.Range(0, 2);
            var subjectB = Observable.Range(2, 2);
            var subjectC = Observable.Range(4, 2);
            var subjectD = Observable.Range(6, 2);

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString())),
                subjectC.And(subjectD).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))                
                )
                .Subscribe(stats);

            Assert.AreEqual(4, stats.NextCount);
            Assert.AreEqual("0,2", stats.NextValues[0]);
            Assert.AreEqual("4,6", stats.NextValues[1]);
            Assert.AreEqual("1,3", stats.NextValues[2]);
            Assert.AreEqual("5,7", stats.NextValues[3]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void raises_error_when_subscription_is_repeated_within_pattern()
        {
            var subjectA = new Subject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectA).Then((x, y) => (string)null)
                )
                .Subscribe(stats);

            Assert.IsTrue(stats.ErrorCalled);
            Assert.IsTrue(stats.Error is ArgumentException);
        }

        [Test]
        public void subscribes_once_when_subscription_is_repeated_within_join()
        {
            var subjectA = new StatsSubject<int>();
            var subjectB = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                subjectA.And(subjectB).Then((x, y) => (string)null),
                subjectB.And(subjectA).Then((x, y) => (string)null)
                )
                .Subscribe(stats);

            Assert.AreEqual(1, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
        }

        [Test]
        public void merges_multiple_joins_that_share_sources()
        {
            var subjectA = new Subject<int>();
            var subjectB = new Subject<int>();
            var subjectC = new Subject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                    subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString())),
                    subjectA.And(subjectC).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            subjectA.OnNext(0);
            subjectB.OnNext(1);

            subjectA.OnNext(0);
            subjectC.OnNext(2);

            Assert.AreEqual(0, stats.NextCount);
        }

        [Test]
        public void errors_cause_all_subscriptions_to_be_removed()
        {
            var subjectA = new StatsSubject<int>();
            var subjectB = new StatsSubject<int>();
            var subjectC = new StatsSubject<int>();
            var subjectD = new StatsSubject<int>();

            var stats = new StatsSubject<string>();

            Observable.Join(
                    subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString())),
                    subjectC.And(subjectD).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            Assert.AreEqual(1, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
            Assert.AreEqual(1, subjectC.SubscriptionCount);
            Assert.AreEqual(1, subjectD.SubscriptionCount);

            subjectA.OnError(new Exception());

            Assert.AreEqual(0, subjectA.SubscriptionCount);
            Assert.AreEqual(0, subjectB.SubscriptionCount);
            Assert.AreEqual(0, subjectC.SubscriptionCount);
            Assert.AreEqual(0, subjectD.SubscriptionCount);
        }

        [Test]
        public void complete_does_not_unsubscribe_from_other_subjects()
        {
            var subjectA = new StatsSubject<int>();
            var subjectB = new StatsSubject<int>();
            var subjectC = new StatsSubject<int>();
            var subjectD = new StatsSubject<int>();

            var stats = new StatsSubject<string>();

            Observable.Join(
                    subjectA.And(subjectB).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString())),
                    subjectC.And(subjectD).Then((x, y) => String.Concat(x.ToString(), ",", y.ToString()))
                )
                .Subscribe(stats);

            Assert.AreEqual(1, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
            Assert.AreEqual(1, subjectC.SubscriptionCount);
            Assert.AreEqual(1, subjectD.SubscriptionCount);

            subjectA.OnCompleted();

            Assert.AreEqual(0, subjectA.SubscriptionCount);
            Assert.AreEqual(0, subjectB.SubscriptionCount);
            Assert.AreEqual(1, subjectC.SubscriptionCount);
            Assert.AreEqual(1, subjectD.SubscriptionCount);
        }
    }
}
