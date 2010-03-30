package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.tests.mocks.ManualObservable;
	
	[TestCase]
	public class ContainsFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.where(function(a:Object,b:Object) : Boolean { return true; });
		}
		
		[Test]
		public function next_is_only_called_once() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.contains(1);
			
			var nextCount : int = 0;
			
			obs.subscribeFunc(function(pl:int):void
			{
				nextCount++;
			});
			
			manObs.onNext(0);
			manObs.onNext(1); // onComplete should raise here
			manObs.onNext(2);
			manObs.onNext(1);
			manObs.onCompleted();
			
			Assert.assertEquals(1, nextCount);
		}
		
		[Test]
		public function next_is_raised_with_true_when_objects_are_equal() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.contains(1);
			
			var nextCalled : Boolean = false;
			var completeCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { nextCalled = true; },
				function() : void { completeCalled = true; }
			);
			
			manObs.onNext(1); // onComplete should raise here
			
			Assert.assertTrue(nextCalled);
			Assert.assertTrue(completeCalled);
		}
		
		[Test]
		public function next_is_raised_with_true_when_comparer_returns_true() : void
		{
			testWithComparer(true, false, true, true);
		}
		
		[Test]
		public function next_is_not_raised_when_comparer_returns_false() : void
		{
			testWithComparer(false, false, false, false);
		}
		
		[Test]
		public function next_is_raised_with_true_when_comparer_returns_zero() : void
		{
			testWithComparer(0, false, true, true);
		}
		
		[Test]
		public function next_is_not_raised_when_comparer_returns_one() : void
		{
			testWithComparer(1, false, false, false);
		}
		
		[Test]
		public function next_is_raised_with_false_when_source_ends_without_match() : void
		{
			testWithComparer(false, true, true, false);
		}
		
		private function testWithComparer(comparerReturnValue : Object, complete : Boolean, expectCall : Boolean, expectMatch : Boolean) : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.contains(1, 
				function(a:Object,b:Object) : Object { return comparerReturnValue; });
			
			var nextCalled : Boolean = false;
			var nextResult : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:Boolean):void { nextCalled = true; nextResult = pl; }
			);
			
			manObs.onNext(1);
			
			if (complete)
			{
				manObs.onCompleted();
			}
			
			Assert.assertEquals(expectCall, nextCalled);
			Assert.assertEquals(expectMatch, nextResult);
		}
		
		[Test]
		public function next_is_not_raised_when_source_ends_with_error() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.contains(1);
			
			var nextCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:Boolean):void { nextCalled = true; }
			);
			
			manObs.onError(new Error());
			
			Assert.assertFalse(nextCalled);
		}
		
		[Test]
		public function errors_thrown_by_comparer_are_sent_to_onerror() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.contains(0, function(a:int,b:int) : Boolean
			{
				throw new Error();
			});
			
			var nextCalled : Boolean = false;
			var errorCalled : Boolean = false;
			
			obs.subscribeFunc(
				function(pl:int):void { nextCalled = true; },
				function():void { },
				function(e:Error):void { errorCalled = true; }
			);

			manObs.onNext(0);
			
			Assert.assertFalse(nextCalled);
			Assert.assertTrue(errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : ManualObservable = new ManualObservable(int);
			
			var obs : IObservable = manObs.contains(0, function(a:int,b:int) : Boolean
			{
				return true;
			});
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}