using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
using System.Concurrency;

namespace RxAs.Rx4.ProofTests.Testing
{
    [TestFixture]
    public class TestSchedulerFixture
    {
        [Test]
		public void immediate_actions_are_called_before_future_actions()
		{
			var aWasCalled = false;
			var bWasCalled = false;
			var cWasCalled = false;
			Action actionA = () => aWasCalled = true;
			Action actionB = () => bWasCalled = true;
			Action actionC = () => cWasCalled = true;
			
			var scheduler = new TestScheduler();
			
			scheduler.Schedule(actionA, 10);
			
			scheduler.RunTo(10);
			Assert.IsTrue(aWasCalled);

            scheduler.Schedule(actionB, 10);
            scheduler.Schedule(actionC, 0);

            scheduler.RunTo(11);
            Assert.IsTrue(cWasCalled);
            Assert.IsFalse(bWasCalled);

            scheduler.RunTo(20);
            Assert.IsTrue(bWasCalled);
		}
    }
}
