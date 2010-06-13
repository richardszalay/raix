using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using RxAs.Rx4.ProofTests.Mock;

namespace RxAs.Rx4.ProofTests.Operators
{
    public class FromEventFixture
    {
		private EventOwner ev;
		private IObservable<IEvent<EventArgs>> obs;
		
		[SetUp]
		public void Setup()
		{
			ev = new EventOwner();
            obs = Observable.FromEvent<EventArgs>(e => ev.Event += e, e => ev.Event -= e);
		}
		
		[Test]
		public void event_listener_is_not_added_before_subscrube()
		{
            Assert.IsFalse(ev.HasSubscriptions);
		}
		
		[Test]
		public void event_listener_is_added_after_subscrube() 
		{
            var sub = obs.Subscribe(x => { });

            Assert.IsTrue(ev.HasSubscriptions);
		}
		
		[Test]
		public void event_listener_is_removed_on_unsubscribe() 
		{
            var sub = obs.Subscribe(x => { });
			
			sub.Dispose();

            Assert.IsFalse(ev.HasSubscriptions);
		}
		
		[Test]
		public void multiple_subscribers_do_not_conflict() 
		{
			var subA  = obs.Subscribe(x => { });
            var subB = obs.Subscribe(x => { });

            Assert.IsTrue(ev.HasSubscriptions);
			
			subA.Dispose();
            Assert.IsTrue(ev.HasSubscriptions);

            subB.Dispose();
            Assert.IsFalse(ev.HasSubscriptions);
		}

        [Test]
        [ExpectedException(typeof(Exception))]
        public void exceptions_thrown_from_onnext_are_not_converted_to_onerror_calls()
        {
            var sub = obs.Subscribe(x => { throw new Exception(); }, ex => { });

            ev.Fire();
        }
		
		[Test]
		public void events_are_pushed_to_onNext() 
		{
			var nextCount = 0;

            obs.Subscribe(e => nextCount++);

            ev.Fire();
			Assert.AreEqual(1, nextCount);

            ev.Fire();
            Assert.AreEqual(2, nextCount);
		}
    }
}
