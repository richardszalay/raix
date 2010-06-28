package rx.tests.operators
{
	import asmock.framework.Expect;
	import asmock.framework.MockRepository;
	import asmock.framework.constraints.Is;
	
	import org.flexunit.Assert;
	
	import rx.ICancelable;
	import rx.Observable;
	import rx.impl.ClosureCancelable;
	import rx.scheduling.IScheduler;
	import rx.tests.mocks.ManualScheduler;
	import rx.tests.mocks.StatsObserver; 
	
	[RunWith("asmock.integration.flexunit.ASMockClassRunner")]
	public class IntervalFixture
	{
		[Mock] public static var schedulerMock : IScheduler;
		
		public function IntervalFixture()
		{
		}
		
		
		
		[Test]
		public function does_not_fire_onnext_until_scheduler_returns() : void
		{
			var intervalValue : int = 50;
			
			var returnScheduledAction : ICancelable = ClosureCancelable.empty();
			
			var scheduler : ManualScheduler = new ManualScheduler();
		
			var stats : StatsObserver = new StatsObserver();
			
			Observable.interval(intervalValue, scheduler).subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertFalse(stats.completedCalled);
			
			scheduler.runNext();
			Assert.assertEquals(1, stats.nextCount);
			
			scheduler.runNext();
			Assert.assertEquals(2, stats.nextCount);
			
			scheduler.runNext();
			Assert.assertEquals(3, stats.nextCount);
		}
		
		[Test]
		public function unsubscribing_cancels_scheduled_action() : void
		{
			var intervalValue : int = 50;
			
			var returnScheduledAction : ICancelable = ClosureCancelable.empty();
			
			var scheduler : ManualScheduler = new ManualScheduler();
		
			var stats : StatsObserver = new StatsObserver();
			
			var subscription : ICancelable = 
				Observable.interval(intervalValue, scheduler).subscribeWith(stats);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertEquals(1, scheduler.queueSize);
			
			subscription.cancel();
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertEquals(0, scheduler.queueSize);
		}

		[Test]
		public function uses_scheduler_with_dueTime() : void
		{
			var intervalValue : int = 50;
			
			var repository : MockRepository = new MockRepository();
			
			var returnScheduledAction : ICancelable = ClosureCancelable.empty();
			
			var scheduler : IScheduler = IScheduler(repository.createStrict(IScheduler));
			Expect.call(scheduler.schedule(null, 0))
				.constraints([Is.anything(), Is.equal(intervalValue)])
				.returnValue(returnScheduledAction);
				
			repository.replay(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.interval(intervalValue, scheduler).subscribeWith(stats);
			
			repository.verify(scheduler);
		}
		
		[Test]
		public function subsequent_calls_to_scheduler_pass_dueTime() : void
		{
			var intervalValue : int = 50;
			
			var repository : MockRepository = new MockRepository();
			
			var returnScheduledAction : ICancelable = ClosureCancelable.empty();
			
			var calledScheduledAction : Boolean = false;
			
			var scheduler : IScheduler = IScheduler(repository.createStrict(IScheduler));
			Expect.call(scheduler.schedule(null, 0))
				.constraints([Is.anything(), Is.equal(intervalValue)])
				.doAction(function(action:Function, ...args) : ICancelable
				{
					if (!calledScheduledAction)
					{
						calledScheduledAction = true;
						action();
					}
					
					return ClosureCancelable.empty();
				})
				.repeat.twice();
				
			repository.replay(scheduler);
			
			var stats : StatsObserver = new StatsObserver();
			
			Observable.interval(intervalValue, scheduler).subscribeWith(stats);
			
			repository.verify(scheduler);
		}
	}
}