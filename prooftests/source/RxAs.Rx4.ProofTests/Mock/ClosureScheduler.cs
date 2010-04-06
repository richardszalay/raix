using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Concurrency;

namespace RxAs.Rx4.ProofTests.Mock
{
    public class ClosureScheduler : IScheduler
    {
        private Func<Action, IDisposable> scheduleFunc;

        public ClosureScheduler(Func<Action, IDisposable> scheduleFunc)
        {
            this.scheduleFunc = scheduleFunc;
        }

        public DateTimeOffset Now
        {
            get { throw new NotImplementedException(); }
        }

        public IDisposable Schedule(Action action, TimeSpan dueTime)
        {
            throw new NotImplementedException();
        }

        public IDisposable Schedule(Action action)
        {
            return scheduleFunc(action);
        }
    }
}
