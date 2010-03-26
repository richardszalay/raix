package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.Observable;
	import rx.impl.ClosureScheduledAction;
	import rx.scheduling.IScheduledAction;
	import rx.scheduling.IScheduler;
	import rx.tests.mocks.ClosureScheduler;
	import rx.tests.mocks.NullScheduler;
	
	[TestCase]
	public class EmptyFixture
	{
		[Test]
		public function immediately_completes_when_subscribed_to_with_no_scheduler() : void
		{
			var obs : IObservable = Observable.empty();
			
			var completed : Boolean = false;
			
			obs.subscribeFunc(null, function():void
			{
				completed = true;	
			});
			
			Assert.assertTrue(completed);
		}
		
		[Test]
		public function publishing_is_run_through_publishing_scheduler() : void
		{
			var sched : IScheduler = new NullScheduler();
			
			var obs : IObservable = Observable.empty(sched);
			
			var completed : Boolean = false;
			
			obs.subscribeFunc(null, function():void
			{
				completed = true;	
			});
			
			Assert.assertFalse(completed);
		}
		
		[Test]
		public function unsubscribing_does_not_throw_an_error() : void
		{
			var obs : IObservable = Observable.empty();
			
			var subscription : ISubscription = obs.subscribeFunc(null);
			subscription.unsubscribe();
		}
		
		[Test(description = "This is known to fail")]
        public function schedule_is_cancelled_when_completed() : void
        {
            var disposed : Boolean = false;

            var scheduler : ClosureScheduler = new ClosureScheduler(function(action:Function, dueTime:uint) : IScheduledAction
            {
            	action();
            	
            	return new ClosureScheduledAction(function():void
            	{
            		disposed = true;
            	});
            });

            var obs : IObservable = Observable.empty(scheduler);

           var subscription : ISubscription = obs.subscribeFunc(null);

            Assert.assertTrue("This is known to fail", disposed);
        }
	}
}