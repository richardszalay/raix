using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace RxAs.Rx4.ProofTests.Mock
{
    public class EventOwner
    {
        private int subscriberCount = 0;

        private event EventHandler<EventArgs> internalEvent;

        public event EventHandler<EventArgs> Event
        {
            add { Interlocked.Increment(ref subscriberCount); internalEvent += value; }
            remove { Interlocked.Decrement(ref subscriberCount); internalEvent -= value; }
        }

        public void Fire()
        {
            var handler = internalEvent;

            if (handler != null)
            {
                handler(this, EventArgs.Empty);
            }
        }

        public IObservable<IEvent<EventArgs>> GetObservableEvent()
        {
            return Observable.FromEvent<EventArgs>(
                x => Event += x,
                x => Event -= x
                );
        }

        public bool HasSubscriptions
        {
            get { return internalEvent != null; }
        }

        public int SubscriptionCount
        {
            get { return subscriberCount; }
        }
    }
}
