package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.ManualScheduler;
	
	[TestCase]
	public class TakeFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.take(3);
		}
		
		[Test]
		public function complete_is_called_after_specified_values_taken() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.take(3);
			
			var nextCount : uint = 0;
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { nextCount++; },
				function():void { completeCalled = true; }	
			);
			
			manObs.onNext(0);
			Assert.assertEquals(1, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(2, nextCount);
			Assert.assertFalse(completeCalled);
			
			manObs.onNext(0);
			Assert.assertEquals(3, nextCount);
			Assert.assertTrue(completeCalled);
		}

		[Test]
		public function next_is_raised_through_scheduler() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.take(3, scheduler);
			
			var nextCount : uint = 0;
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { nextCount++; },
				function():void { completeCalled = true; }	
			);
			
			manObs.onNext(0);
			manObs.onNext(0);			
			manObs.onNext(0);
			
			Assert.assertEquals(0, nextCount);
			Assert.assertFalse(completeCalled);
			
			scheduler.runAll();
			
			Assert.assertEquals(3, nextCount);
			Assert.assertTrue(completeCalled);
		}
		
		[Test]
		public function completed_is_raised_through_scheduler() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.take(3, scheduler);
			
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { },
				function():void { completeCalled = true; }	
			);
			
			manObs.onCompleted();
			
			Assert.assertFalse(completeCalled);
			
			scheduler.runAll();
			
			Assert.assertTrue(completeCalled);
		}
		
		[Test]
		public function error_is_raised_through_scheduler() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			var scheduler : ManualScheduler = new ManualScheduler();
			
			var obs : IObservable = manObs.take(3, scheduler);
			
			var errorCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { },
				function():void{},
				function(err:Error):void { errorCalled = true; }	
			);
			
			manObs.onError(new Error());
			
			Assert.assertFalse(errorCalled);
			
			scheduler.runAll();
			
			Assert.assertTrue(errorCalled);
		}

		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable();
			
			var obs : IObservable = manObs.take(3);
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}