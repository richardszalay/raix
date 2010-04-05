using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class AmbFixture
    {
        [Test]
		public void other_sources_are_unsubscribed_when_value_is_received()
		{
            var sourceA = new EventOwner();
            var sourceB = new EventOwner();
            var sourceC = new EventOwner();

            var obs = Observable.Amb(
                sourceA.GetObservableEvent(),
                sourceB.GetObservableEvent(),
                sourceC.GetObservableEvent()
                );

            var stats = new StatsObserver<IEvent<EventArgs>>();
            obs.Subscribe(stats);

            sourceB.Fire();

            Assert.IsFalse(sourceA.HasSubscriptions);
            Assert.IsTrue(sourceB.HasSubscriptions);
            Assert.IsFalse(sourceC.HasSubscriptions);
		}

        [Test]
        public void all_sources_are_unsubscribed_when_complete_is_received()
        {
            var sourceA = new EventOwner();
            var sourceC = new EventOwner();

            var obs = Observable.Amb(
                sourceA.GetObservableEvent(),
                Observable.Empty<IEvent<EventArgs>>(),
                sourceC.GetObservableEvent()
                );

            var stats = new StatsObserver<IEvent<EventArgs>>();
            obs.Subscribe(stats);

            Assert.IsFalse(sourceA.HasSubscriptions);
            Assert.IsFalse(sourceC.HasSubscriptions);
        }

        [Test]
        public void all_sources_are_unsubscribed_when_error_is_received()
        {
            var sourceA = new EventOwner();
            var sourceB = new EventOwner();

            var obs = Observable.Amb(
                sourceA.GetObservableEvent(),
                sourceB.GetObservableEvent(),
                Observable.Throw<IEvent<EventArgs>>(new Exception())
                );

            var stats = new StatsObserver<IEvent<EventArgs>>();
            obs.Subscribe(stats);

            Assert.IsFalse(sourceA.HasSubscriptions);
            Assert.IsFalse(sourceB.HasSubscriptions);
            Assert.IsTrue(stats.ErrorCalled);
        }

    }
}
