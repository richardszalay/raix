using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using RxAs.Rx4.ProofTests.Mock;
using NUnit.Framework;

namespace RxAs.Rx4.ProofTests.Operators
{
    public class ThrottleFixture
    {
        public void scheduler_is_used_to_reset_throttle()
        {
            ManualScheduler scheduler = new ManualScheduler();

            scheduler.Now = DateTime.Now;

            Subject<int> subject = new Subject<int>();

            var stats = new StatsObserver<int>();

            subject.Throttle(TimeSpan.FromSeconds(1), scheduler).Subscribe(stats);

            subject.OnNext(0);
            subject.OnNext(1);

            //Assert.AreEqual(1, stats.NextCount);
            //Assert.AreEqual(1, scheduler.QueueSize);

            scheduler.Now = scheduler.Now.AddSeconds(1);

            scheduler.RunNext();
            scheduler.RunNext();

            subject.OnNext(2);

            Assert.AreEqual(2, stats.NextCount);
            Assert.AreEqual(1, scheduler.QueueSize);
        }

        public void exact_time_is_not_allowed()
        {
            ManualScheduler scheduler = new ManualScheduler();

            StatsSubject<int> subject = new StatsSubject<int>();

            var stats = new StatsObserver<int>();

            scheduler.Now = DateTime.Now;

            subject
                .Throttle(TimeSpan.FromSeconds(1), scheduler)
                .Subscribe(stats);
            
            subject.OnNext(0);

            scheduler.Now = scheduler.Now.AddSeconds(5).AddMilliseconds(1);
            subject.OnNext(1);

            Assert.AreEqual(1, stats.NextCount);
        }
    }
}
