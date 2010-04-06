using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace RxAs.Rx4.ProofTests.Mock
{
    public class EventOwner
    {
        public event EventHandler<EventArgs> Event;

        public void Fire()
        {
            var handler = Event;

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
            get { return Event != null; }
        }
    }
}
