using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;
using System.Threading;
using System.Concurrency;
using System.Diagnostics;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class SkipUntilFixture
    {
        [Test]
        public void returns_values_after_other_emits_value()
        {
            var eventOwnerA = new EventOwner();
            var eventOwnerB = new EventOwner();

            var observableA = Observable.FromEvent<EventArgs>(x => eventOwnerA.Event += x, x => eventOwnerA.Event -= x);
            var observableB = Observable.FromEvent<EventArgs>(x => eventOwnerB.Event += x, x => eventOwnerB.Event -= x);

            var stats = new StatsObserver<IEvent<EventArgs>>();
            
            observableA.SkipUntil(observableA)
                .Subscribe(stats);

            eventOwnerA.Fire();
            eventOwnerA.Fire();
            eventOwnerA.Fire();
            eventOwnerB.Fire();
            eventOwnerA.Fire();

            Assert.AreEqual(3, stats.NextCount);
        }

        [Test]
        public void complete_does_not_equate_to_value()
        {
            var eventOwnerA = new EventOwner();

            var observableA = Observable.FromEvent<EventArgs>(x => eventOwnerA.Event += x, x => eventOwnerA.Event -= x);

            var stats = new StatsObserver<IEvent<EventArgs>>();
            observableA
                .SkipUntil(Observable.Empty<int>())
                .Subscribe(stats);

            eventOwnerA.Fire();
            eventOwnerA.Fire();
            eventOwnerA.Fire();

            Assert.AreEqual(0, stats.NextCount);
            Assert.IsFalse(stats.CompletedCalled);
        }

        [Test]
        public void unsubscribes_from_other_after_value()
        {
            var stats = new StatsObserver<int>();
            Observable.Range(0, 5).SkipUntil(Observable.Return(1).Concat(Observable.Throw<int>(new ApplicationException())))
                .Subscribe(stats);
        }

    }
}
