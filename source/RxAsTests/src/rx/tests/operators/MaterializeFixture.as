package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ISubscription;
	import rx.Notification;
	import rx.NotificationKind;
	import rx.Subject;
	
	[TestCase]
	public class MaterializeFixture
	{
		protected function createEmptyObservable(source:IObservable):IObservable
		{
			return source.materialize();
		}
		
		[Test]
		public function notification_is_applied_to_onnext() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize();
			
			var nextCount : int = 0;
			
			obs.subscribeFunc(function(pl:Notification):void
			{
				nextCount++;
				
				Assert.assertEquals(NotificationKind.ON_NEXT, pl.kind);
				Assert.assertEquals(5, pl.value);
			});
			
			manObs.onNext(5);
			
			Assert.assertEquals(1, nextCount);
		}
		
		[Test]
		public function complete_is_sent_as_next_and_completed() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize();
			
			var nextCount : int = 0;
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:Notification):void
				{
					nextCount++;
					Assert.assertEquals(NotificationKind.ON_COMPLETED, pl.kind);
				},
				function():void { completeCalled = true; }
			);
			
			manObs.onCompleted();
			
			Assert.assertEquals(1, nextCount);
			Assert.assertTrue(completeCalled);
		}
		
		[Test]
		public function error_is_sent_as_next_and_completed() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.materialize();
			
			var nextCount : int = 0;
			var completeCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			var err : Error = new Error();
			
			obs.subscribeFunc(
				function(pl:Notification):void
				{
					nextCount++;
					Assert.assertEquals(NotificationKind.ON_ERROR, pl.kind);
					Assert.assertStrictlyEquals(err, pl.error);
				},
				function():void { completeCalled = true; },
				function(e:Error):void { errorCalled = true; }
			);
			
			manObs.onError(err);
			
			Assert.assertEquals(1, nextCount);
			Assert.assertTrue(completeCalled);
			Assert.assertFalse(errorCalled);
		}
		
		[Test]
		public function unsubscribes_from_source_on_completed() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onCompleted();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_error() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribeFunc(function(pl:int):void
			{
			});
			
			manObs.onError(new Error());
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function unsubscribes_from_source_on_unsubscribe() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var subs : ISubscription = obs.subscribeFunc(function(pl:int):void
			{
			});
			
			subs.unsubscribe();
			
			Assert.assertFalse(manObs.hasSubscriptions);
		}
		
		[Test]
		public function is_normalized_for_oncompleted() : void
		{
			var manObs : Subject = new Subject(Object);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var nextCalled : int = 0;
			var errorCalled : Boolean = false;
			var completedCalled : int = 0;
			
			var subs : ISubscription = obs.subscribeFunc(
				function(pl:int):void { nextCalled++; },
				function():void { completedCalled++; },
				function(e:Error):void { errorCalled = true; }
			);
			
			manObs.onCompleted();
			manObs.onNext(new Object());
			manObs.onError(new Error());
			
			Assert.assertEquals(1, nextCalled);
			Assert.assertEquals(1, completedCalled);
			Assert.assertFalse(errorCalled);
		}
		
		[Test]
		public function is_normalized_for_onerror() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			var nextCalled : int = 0;
			var completedCalled : int = 0;
			
			var subs : ISubscription = obs.subscribeFunc(
				function(pl:int):void { nextCalled++; },
				function():void { completedCalled++; },
				function(e:Error):void { }
			);
			
			manObs.onError(new Error());
			manObs.onNext(new Object());
			manObs.onCompleted();
			
			Assert.assertEquals(1, nextCalled);
			Assert.assertEquals(1, completedCalled);
		}
	}
}