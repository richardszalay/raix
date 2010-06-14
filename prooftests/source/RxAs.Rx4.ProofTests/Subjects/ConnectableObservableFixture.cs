using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Subjects
{
    [TestFixture]
    public class ConnectableObservableFixture
    {
        [Test]
        public void uses_subject_for_subscriptions()
        {
            IObservable<int> source = Observable.Empty<int>();
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            Assert.IsFalse(subject.HasSubscriptions);

            var sub = connectable.Subscribe(stats);

            Assert.IsTrue(subject.HasSubscriptions);

            sub.Dispose();

            Assert.IsFalse(subject.HasSubscriptions);
        }

        [Test]
        public void disconnecting_does_not_remove_subscriptions()
        {
            IObservable<int> source = Observable.Empty<int>();
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            Assert.IsFalse(subject.HasSubscriptions);

            var sub = connectable.Subscribe(stats);

            Assert.IsTrue(subject.HasSubscriptions);

            connectable.Connect().Dispose();

            Assert.IsTrue(subject.HasSubscriptions);
        }

        [Test]
        public void values_send_before_completion_are_ignored()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            source.OnNext(0);
            source.OnCompleted();
            source.OnError(new Exception());

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
            Assert.IsFalse(stats.ErrorCalled);
        }

        [Test]
        public void connecting_subscribes_to_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            Assert.IsFalse(source.HasSubscriptions);

            connectable.Connect();

            Assert.IsTrue(source.HasSubscriptions);
        }

        [Test]
        public void disconnecting_subscribes_to_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            Assert.IsFalse(source.HasSubscriptions);

            connectable.Connect().Dispose();

            Assert.IsFalse(source.HasSubscriptions);
        }

        [Test]
        public void connecting_multiple_times_does_not_subscribe_to_source_multiple_times()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            connectable.Connect();
            connectable.Connect();

            Assert.AreEqual(1, source.SubscriptionCount);
        }

        [Test]
        public void disconnecting_last_of_multiple_connections_subscribes_to_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            Assert.IsFalse(source.HasSubscriptions);

            connectable.Connect();
            connectable.Connect().Dispose();

            Assert.IsFalse(source.HasSubscriptions);
        }

        [Test]
        public void disconnecting_first_of_multiple_connections_subscribes_to_source()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            Assert.IsFalse(source.HasSubscriptions);

            var connectionA = connectable.Connect();
            var connectionB = connectable.Connect();

            connectionA.Dispose();

            Assert.IsFalse(source.HasSubscriptions);
        }

        [Test]
        public void operations_are_passed_on_once_connected()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            source.OnNext(0);

            connectable.Connect();

            source.OnNext(1);

            Assert.IsTrue(stats.NextCalled);
            Assert.AreEqual(1, stats.NextValues[0]);
            Assert.IsFalse(stats.CompletedCalled);
            Assert.IsFalse(stats.ErrorCalled);
        }

        [Test]
        public void operation_order_is_honoured_prior_to_connection()
        {
            StatsObserver<int> stats = new StatsObserver<int>();

            StatsSubject<int> source = new StatsSubject<int>();
            StatsSubject<int> subject = new StatsSubject<int>();

            ConnectableObservable<int> connectable = new ConnectableObservable<int>(source, subject);

            var sub = connectable.Subscribe(stats);

            source.OnNext(0);
            source.OnCompleted();

            connectable.Connect();

            source.OnNext(1);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
            Assert.IsFalse(stats.ErrorCalled);
        }
    }
}
