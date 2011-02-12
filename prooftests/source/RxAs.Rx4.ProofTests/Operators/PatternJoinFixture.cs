using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    [TestFixture]
    public class PatternJoinFixture
    {
        [Test]
        public void complete_does_not_unsubscribe_from_other_subjects()
        {
            var subjectA = new StatsSubject<int>();
            var subjectB = new StatsSubject<int>();
            var subjectC = new StatsSubject<int>();
            var subjectD = new StatsSubject<int>();

            var stats = new StatsObserver<string>();

            Observable.Join(
                    subjectA.And(subjectB).Then((x,y) => x.ToString() + "," + y.ToString()),
                    subjectC.And(subjectD).Then((x,y) => x.ToString() + "," + y.ToString())
                )
                .Subscribe(stats);

            Assert.AreEqual(1, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
            Assert.AreEqual(1, subjectC.SubscriptionCount);
            Assert.AreEqual(1, subjectD.SubscriptionCount);

            subjectA.OnCompleted();

            Assert.AreEqual(0, subjectA.SubscriptionCount);
            Assert.AreEqual(1, subjectB.SubscriptionCount);
            Assert.AreEqual(1, subjectC.SubscriptionCount);
            Assert.AreEqual(1, subjectD.SubscriptionCount);
        }
    }
}
