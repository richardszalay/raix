package rx.tests.operators
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.Observable;
	import rx.tests.mocks.ManualScheduler;
	
	public class FromEventFixture
	{
		private static const TEST_EVENT : String = "test";
			
		private var ev : EventDispatcher;
		private var obs : IObservable;
		
		[Before]
		public function setup() : void
		{
			ev = new EventDispatcher();
			obs = Observable.fromEvent(ev, TEST_EVENT);
		}
		
		[Test]
		public function event_listener_is_not_added_before_subscrube() : void
		{
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function event_listener_is_added_after_subscrube() : void
		{
			var sub : ISubscription = obs.subscribeFunc(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function event_listener_is_removed_on_unsubscribe() : void
		{
			var sub : ISubscription = obs.subscribeFunc(function():void{});
			
			sub.unsubscribe();
			
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function multiple_subscribers_do_not_conflict() : void
		{
			var subA : ISubscription = obs.subscribeFunc(function():void{});
			var subB : ISubscription = obs.subscribeFunc(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
			
			subA.unsubscribe();
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
			
			subB.unsubscribe();
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function events_are_pushed_to_onNext() : void
		{
			obs = Observable.fromEvent(ev, TEST_EVENT);
			
			var nextCount : uint = 0;
			
			obs.subscribeFunc(function():void { nextCount++ });
			
			ev.dispatchEvent(new Event(TEST_EVENT));
			Assert.assertEquals(1, nextCount);
			
			ev.dispatchEvent(new Event(TEST_EVENT));
			Assert.assertEquals(2, nextCount);
		}
	}
}