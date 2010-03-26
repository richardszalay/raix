using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx2.ProofTests.Mock;

namespace RxAs.Rx2.ProofTests.Operators
{
    public class EmptyEventFixture
    {
        private IObservable<int> obs;
		
		[SetUp]
		public void Setup()
		{
            obs = Observable.Empty<int>();
		}
		
		[Test]
		public void immediately_completes_when_subscribed_to_with_no_scheduler()
		{
            obs = Observable.Empty<int>();

            bool completed = false;

            using (obs.Subscribe(x => { }, () => completed = true))
            {
                Assert.IsTrue(completed);
            }
		}

        [Test]
        public void publishing_is_run_through_publishing_scheduler()
        {
            ManualScheduler scheduler = new ManualScheduler();

            obs = Observable.Empty<int>(scheduler);

            bool completed = false;

            var subs = obs.Subscribe(x => { }, () => completed = true);

            Assert.IsFalse(completed);

            scheduler.RunAll();

            Assert.IsTrue(completed);
        }

        [Test]
        public void schedule_is_cancelled_when_completed()
        {
            bool disposed = false;

            ClosureScheduler scheduler = new ClosureScheduler(
                a => { a(); return new ClosureDisposable(() => disposed = true); }
                );

            obs = Observable.Empty<int>(scheduler);

            var subs = obs.Subscribe(x => { }, () => { });

            Assert.IsTrue(disposed);
        }
    }
}
