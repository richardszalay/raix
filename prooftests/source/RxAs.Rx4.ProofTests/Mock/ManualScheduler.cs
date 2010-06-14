using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Concurrency;
using System.Disposables;

namespace RxAs.Rx4.ProofTests.Mock
{
    public class ManualScheduler : IScheduler
    {
        private Queue<Action> actions = new Queue<Action>();

        public DateTimeOffset Now
        {
            get;
            set;
        }

        public IDisposable Schedule(Action action, TimeSpan dueTime)
        {
            actions.Enqueue(action);

            return Disposable.Create(() => Remove(action));
        }

        public IDisposable Schedule(Action action)
        {
            actions.Enqueue(action);

            return Disposable.Create(() => Remove(action));
        }

        private void Remove(Action action)
        {
            List<Action> actionsList = actions.ToList();

            actionsList.Remove(action);

            actions = new Queue<Action>(actionsList);
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

        public int QueueSize
        {
            get { return actions.Count; }
        }
    }
}
