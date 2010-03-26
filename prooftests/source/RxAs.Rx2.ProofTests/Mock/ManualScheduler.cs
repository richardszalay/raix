using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Concurrency;
using System.Disposables;

namespace RxAs.Rx2.ProofTests.Mock
{
    public class ManualScheduler : IScheduler
    {
        private Queue<Action> actions = new Queue<Action>();

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
            actions.Enqueue(action);

            return Disposable.Create(() => {  });
        }

        public void RunAll()
        {
            while (actions.Count > 0)
            {
                actions.Dequeue()();
            }
        }

        public void RunNext()
        {
            if (actions.Count > 0)
            {
                actions.Dequeue()();
            }
        }
    }
}
