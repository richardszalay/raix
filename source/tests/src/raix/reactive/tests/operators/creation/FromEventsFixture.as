package raix.reactive.tests.operators.creation
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.ManualScheduler;
	
	public class FromEventsFixture
	{
		private static const TEST_EVENT_A : String = "testA";
		private static const TEST_EVENT_B : String = "testB";
			
		private var ev : EventDispatcher;
		private var obs : IObservable;
		
		[Before]
		public function setup() : void
		{
			ev = new EventDispatcher();
			obs = Observable.fromEvents(ev, [TEST_EVENT_A, TEST_EVENT_B]);
		}
		
		[Test]
		public function event_listener_is_not_added_before_subscrube() : void
		{
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_A));
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_B));
		}
		
		[Test]
		public function event_listener_is_added_after_subscrube() : void
		{
			var sub : ICancelable = obs.subscribe(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_A));
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_B));
		}
		
		[Test]
		public function event_listener_is_removed_on_unsubscribe() : void
		{
			var sub : ICancelable = obs.subscribe(function():void{});
			
			sub.cancel();
			
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_A));
		}
		
		[Test]
		public function multiple_subscribers_do_not_conflict() : void
		{
			var subA : ICancelable = obs.subscribe(function():void{});
			var subB : ICancelable = obs.subscribe(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_A));
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_B));
			
			subA.cancel();
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_A));
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT_B));
			
			subB.cancel();
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_A));
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_B));
		}
		
		[Test]
		public function events_are_pushed_to_onNext() : void
		{
			obs = Observable.fromEvents(ev, [TEST_EVENT_A, TEST_EVENT_B]);
			
			var nextCount : uint = 0;
			
			obs.subscribe(function():void { nextCount++ });
			
			ev.dispatchEvent(new Event(TEST_EVENT_A));
			Assert.assertEquals(1, nextCount);
			
			ev.dispatchEvent(new Event(TEST_EVENT_B));
			Assert.assertEquals(2, nextCount);
		}
	}
}