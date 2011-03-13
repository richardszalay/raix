package rx.tests.operators.creation
{
	import flash.events.*;
	import flash.errors.*;
	
	import org.flexunit.Assert;
	
	import rx.ICancelable;
	import rx.IObservable;
	import rx.Observable;
	import rx.tests.mocks.StatsObserver;
	
	public class FromErrorEventsFixture
	{
		private static const TEST_EVENT_A : String = "testA";
		private static const TEST_EVENT_B : String = "testB";
			
		private var ev : EventDispatcher;
		private var obs : IObservable;
		
		[Before]
		public function setup() : void
		{
			ev = new EventDispatcher();
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B]);
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
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT_B));
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
		public function events_are_pushed_to_onError() : void
		{
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B]);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new ErrorEvent(TEST_EVENT_A, false, false, "test"));
			Assert.assertEquals(1, stats.errorCount);
		}
		
		[Test]
		public function ioerrorevent_is_mapped_to_ioerror() : void
		{
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B]);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new IOErrorEvent(TEST_EVENT_A, false, false, "test"));
			Assert.assertTrue(stats.error is IOError);
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function securityerrorevent_is_mapped_to_securityerror() : void
		{
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B]);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new SecurityErrorEvent(TEST_EVENT_A, false, false, "test"));
			Assert.assertTrue(stats.error is SecurityError);
			Assert.assertEquals("test", stats.error.message);
		}

		[Test]
		public function errorevent_is_mapped_to_error() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT_A);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new ErrorEvent(TEST_EVENT_A, false, false, "test"));
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function other_event_types_are_mapped_to_error() : void
		{
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B]);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new CustomEvent(TEST_EVENT_A, "test"));
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function custom_formatter_is_used_to_map_event() : void
		{
			obs = Observable.fromErrorEvents(int, ev, [TEST_EVENT_A, TEST_EVENT_B], false, 0, function(e:Event):Error
			{
				return new Error("test");
			});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new Event(TEST_EVENT_A));
			Assert.assertEquals("test", stats.error.message);
		}
	}
}
	import flash.events.Event;
	

class CustomEvent extends Event
{
	private var _message : String;
	
	public function CustomEvent(type : String, message : String) 
	{
		super(type, false, false);
		
		_message = message;		
	}
	
	public override function toString():String
	{
		return _message;
	}
}