package raix.reactive.tests.operators.creation
{
	import flash.events.*;
	import flash.errors.*;
	
	import org.flexunit.Assert;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class FromErrorEventFixture
	{
		private static const TEST_EVENT : String = "test";
			
		private var ev : EventDispatcher;
		private var obs : IObservable;
		
		[Before]
		public function setup() : void
		{
			ev = new EventDispatcher();
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
		}
		
		[Test]
		public function event_listener_is_not_added_before_subscrube() : void
		{
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function event_listener_is_added_after_subscrube() : void
		{
			var sub : ICancelable = obs.subscribe(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function event_listener_is_removed_on_unsubscribe() : void
		{
			var sub : ICancelable = obs.subscribe(function():void{});
			
			sub.cancel();
			
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function multiple_subscribers_do_not_conflict() : void
		{
			var subA : ICancelable = obs.subscribe(function():void{});
			var subB : ICancelable = obs.subscribe(function():void{});
			
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
			
			subA.cancel();
			Assert.assertTrue(ev.hasEventListener(TEST_EVENT));
			
			subB.cancel();
			Assert.assertFalse(ev.hasEventListener(TEST_EVENT));
		}
		
		[Test]
		public function events_are_pushed_to_onError() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new ErrorEvent(TEST_EVENT, false, false, "test"));
			Assert.assertEquals(1, stats.errorCount);
		}
		
		[Test]
		public function ioerrorevent_is_mapped_to_ioerror() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new IOErrorEvent(TEST_EVENT, false, false, "test"));
			Assert.assertTrue(stats.error is IOError);
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function securityerrorevent_is_mapped_to_securityerror() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new SecurityErrorEvent(TEST_EVENT, false, false, "test"));
			Assert.assertTrue(stats.error is SecurityError);
			Assert.assertEquals("test", stats.error.message);
		}

		[Test]
		public function errorevent_is_mapped_to_error() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new ErrorEvent(TEST_EVENT, false, false, "test"));
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function other_event_types_are_mapped_to_error() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT);
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new CustomEvent(TEST_EVENT, "test"));
			Assert.assertEquals("test", stats.error.message);
		}
		
		[Test]
		public function custom_formatter_is_used_to_map_event() : void
		{
			obs = Observable.fromErrorEvent(int, ev, TEST_EVENT, false, 0, function(e:Event):Error
			{
				return new Error("test");
			});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
			
			ev.dispatchEvent(new Event(TEST_EVENT));
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