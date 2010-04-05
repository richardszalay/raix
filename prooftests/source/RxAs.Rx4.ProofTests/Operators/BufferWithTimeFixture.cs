﻿using System;
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
    public class BufferWithTimeFixture
    {
        [Test]
        public void emits_empty_list_when_no_values_are_available()
        {
            StatsObserver<IList<int>> stats = new StatsObserver<IList<int>>();

            Observable.Never<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(50))
                .Subscribe(stats);

            Thread.Sleep(100);

            Assert.AreEqual(2, stats.NextCount);
        }

        [Test]
        public void timeshift_equal_to_buffer_time_acts_like_no_timeshift()
        {
            StatsObserver<IList<int>> stats = new StatsObserver<IList<int>>();

            Observable.Never<int>()
                .BufferWithTime(TimeSpan.FromMilliseconds(50), TimeSpan.FromMilliseconds(50))
                .Subscribe(stats);

            Thread.Sleep(110);

            Assert.AreEqual(2, stats.NextCount);
        }

        [Test]
        public void timeshift_used_to_offset()
        {
            StatsObserver<IList<int>> stats = new StatsObserver<IList<int>>();

            Observable.Range(0, 3)
                .BufferWithTime(TimeSpan.FromMilliseconds(10), Scheduler.CurrentThread)
                .Subscribe(
                    x => { Trace.WriteLine("Next"); },
                    () => { Trace.WriteLine("Complete"); }
                );

            Assert.AreEqual(2, stats.NextCount);
        }
    }
}
