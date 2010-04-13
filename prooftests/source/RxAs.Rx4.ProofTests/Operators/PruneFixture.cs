using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class PruneFixture
    {
        [Test]
        public void last_value_is_received_after_completed_if_connected_before_completed()
        {
            Subject<int> subject = new Subject<int>();

            var stats= new StatsObserver<int>();

            var obs = subject.Prune();
            var connection = obs.Connect();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);
            subject.OnCompleted();

            obs.Subscribe(stats);

            Assert.AreEqual(1, stats.NextCount);
            Assert.AreEqual(3, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void last_value_is_not_received_after_completed_disconnected_before_completed()
        {
            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune();
            var connection = obs.Connect();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            connection.Dispose();

            subject.OnCompleted();

            obs.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void last_value_is_received_after_completed_if_any_connection_is_disposed()
        {
            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune();
            var connectionA = obs.Connect();
            var connectionB = obs.Connect();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            connectionA.Dispose();

            subject.OnCompleted();

            connectionB.Dispose();

            obs.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void values_are_skipped_when_not_connected()
        {
            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune();
            var connectionA = obs.Connect();
            
            subject.OnNext(1);
            subject.OnNext(2); // last connected value

            connectionA.Dispose();

            subject.OnNext(3); // not connected here

            var connectionB = obs.Connect();

            subject.OnCompleted();

            connectionB.Dispose();

            obs.Subscribe(stats);

            Assert.IsTrue(stats.NextCalled);
            Assert.AreEqual(2, stats.NextValues[0]);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void value_not_received_if_not_connected_for_oncomplete()
        {
            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune();
            var connectionA = obs.Connect();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            connectionA.Dispose();

            subject.OnCompleted();

            var connectionB = obs.Connect();

            obs.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void last_value_is_not_received_before_completed()
        {
            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune();
            var connection = obs.Connect();

            subject.OnNext(1);
            subject.OnNext(2);
            subject.OnNext(3);

            obs.Subscribe(stats);

            Assert.IsFalse(stats.NextCalled);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void scheduler_is_used_to_send_values()
        {
            Subject<int> subject = new Subject<int>();

            var scheduler = new ManualScheduler();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune(scheduler);
            var connection = obs.Connect();

            subject.OnNext(1);
            subject.OnCompleted();

            obs.Subscribe(stats);

            scheduler.RunAll();

            Assert.IsTrue(stats.NextCalled);
            Assert.IsTrue(stats.CompletedCalled);
        }

        [Test]
        public void scheduler_is_not_used_to_sent_complete()
        {
            Subject<int> subject = new Subject<int>();

            var scheduler = new ManualScheduler();

            var stats = new StatsObserver<int>();

            var obs = subject.Prune(scheduler);
            var connection = obs.Connect();

            subject.OnNext(1);
            subject.OnCompleted();

            obs.Subscribe(stats);

            scheduler.RunNext(); // only run one

            Assert.IsTrue(stats.NextCalled);
            Assert.IsTrue(stats.CompletedCalled); // complete is called anyway
        }

        [Test]
        public void source_is_not_subscribed_to_until_connect()
        {
            EventOwner owner = new EventOwner();

            var source = owner.GetObservableEvent();

            var obs = source.Prune();

            Assert.IsFalse(owner.HasSubscriptions);

            obs.Connect();

            Assert.IsTrue(owner.HasSubscriptions);
        }

        [Test]
        public void source_is_only_subscribed_to_once_for_multiple_connections()
        {
            EventOwner owner = new EventOwner();

            var source = owner.GetObservableEvent();

            var obs = source.Prune();
            obs.Connect();
            obs.Connect();

            Assert.AreEqual(1, owner.SubscriptionCount);
        }

        [Test]
        public void source_is_unscribed_from_on_disconnect()
        {
            EventOwner owner = new EventOwner();

            var source = owner.GetObservableEvent();

            var obs = source.Prune();
            var connection = obs.Connect();

            Assert.IsTrue(owner.HasSubscriptions);

            connection.Dispose();

            Assert.IsFalse(owner.HasSubscriptions);
        }

        [Test]
        public void source_is_unscribed_from_if_any_connections_are_disposed()
        {
            EventOwner owner = new EventOwner();

            var source = owner.GetObservableEvent();

            var obs = source.Prune();
            var connectionA = obs.Connect();
            var connectionB = obs.Connect();

            Assert.IsTrue(owner.HasSubscriptions);

            connectionA.Dispose();

            Assert.IsFalse(owner.HasSubscriptions);

            connectionB.Dispose();

            Assert.IsFalse(owner.HasSubscriptions);
        }

        [Test]
        public void source_is_resubscribed_to_if_on_reconnect()
        {
            EventOwner owner = new EventOwner();

            var source = owner.GetObservableEvent();

            var obs = source.Prune();
            var connectionA = obs.Connect();

            Assert.IsTrue(owner.HasSubscriptions);

            connectionA.Dispose();

            Assert.IsFalse(owner.HasSubscriptions);

            var connectionB = obs.Connect();

            Assert.IsTrue(owner.HasSubscriptions);

            connectionB.Dispose();

            Assert.IsFalse(owner.HasSubscriptions);
        }

        [Test]
        public void selector_is_used()
        {
            Assert.Fail("Not implemented");
        }
    }
}
