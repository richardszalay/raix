package rx.tests.operators.flex
{
	import flash.events.ErrorEvent;
	
	import mx.rpc.Fault;
	
	import org.flexunit.Assert;
	
	import rx.FutureCancelable;
	import rx.ICancelable;
	import rx.IObserver;
	import rx.Observer;
	import rx.flex.FlexObservable;
	import rx.flex.IObservableResponder;
	import rx.tests.mocks.StatsObserver;
	
	public class ResponderFixture
	{
		[Test]
		public function emits_result_and_completes() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats);
			
			responder.result(5);
				
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(5, stats.nextValues[0]);
			Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function canceling_subscription_removes_subscriber() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats).cancel();
			
			responder.result(5);
				
			Assert.assertEquals(0, stats.nextCount);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function unsubscription_during_completion_does_not_affect_subsequent_observers() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var subscriptionA : FutureCancelable = new FutureCancelable();
			var observerA : IObserver = Observer.create(null, function():void
			{
				subscriptionA.cancel();
			});
			
			subscriptionA.innerCancelable = responder.subscribeWith(observerA);
			
			var observerB : StatsObserver = new StatsObserver();
			responder.subscribeWith(observerB);
			
			responder.result(5);
				
			Assert.assertEquals(1, observerB.nextCount);
			Assert.assertEquals(5, observerB.nextValues[0]);
			Assert.assertTrue(observerB.completedCalled);
		}
		
		[Test]
		public function emits_fault_as_error_when_fault_is_error() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats);
			
			var e : Error = new Error("test");
			
			responder.fault(e);
				
			Assert.assertStrictlyEquals(e, stats.error);
		}
		
		[Test]
		public function emits_fault_as_fault_when_fault_is_fault() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats);
			
			var e : Fault = new Fault("test", "test2");
			
			responder.fault(e);

			Assert.assertTrue(stats.error is Fault);
			Assert.assertStrictlyEquals(e, stats.error);
		}
		
		[Test]
		public function emits_fault_as_error_when_fault_is_errorevent() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats);
			
			var e : ErrorEvent = new ErrorEvent(ErrorEvent.ERROR, false, false, "test");
			
			responder.fault(e);

			Assert.assertTrue(stats.error is Error);
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function emits_fault_as_error_when_fault_is_unconvertable() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var stats : StatsObserver = new StatsObserver();
			
			responder.subscribeWith(stats);
			
			responder.fault("error message");

			Assert.assertTrue(stats.error is Error);
			Assert.assertEquals("error message", stats.error.message);
		}
		
		[Test]
		public function unsubscription_during_error_does_not_affect_subsequent_observers() : void
		{
			var responder : IObservableResponder = FlexObservable.responder(int);
			
			var subscriptionA : FutureCancelable = new FutureCancelable();
			var observerA : IObserver = Observer.create(null, null, function(e:Error):void
			{
				subscriptionA.cancel();
			});
			
			subscriptionA.innerCancelable = responder.subscribeWith(observerA);
			
			var observerB : StatsObserver = new StatsObserver();
			responder.subscribeWith(observerB);
			
			responder.fault(5);
				
			Assert.assertEquals(1, observerB.errorCount);
		}
	}
}