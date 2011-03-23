package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.OnCompleted;
	import raix.reactive.OnError;
	import raix.reactive.OnNext;
	import raix.reactive.testing.ColdObservable;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	
	[TestCase]
	public class SequenceEqualFixture
	{
		[Test]
		public function returns_true_at_end_of_both_sequences_if_values_match() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(20, new OnCompleted())
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);

			scheduler.runTo(20);

			observer.assertTimings([
				new Recorded(20, new OnNext(true)),
				new Recorded(20, new OnCompleted())
				], Assert.fail);
		}
		
		[Test]
		public function returns_true_at_end_of_both_sequences_if_values_match_using_comparer() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext({v:0})),
					new Recorded(10, new OnNext({v:1})),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext({v:0})),
					new Recorded(10, new OnNext({v:1})),
					new Recorded(20, new OnCompleted())
				]);
			
			left.sequenceEqual(right, function(l:Object,r:Object):Boolean
				{
					return l.v == r.v;
				})
				.subscribeWith(observer);

			scheduler.runTo(20);

			observer.assertTimings([
				new Recorded(20, new OnNext(true)),
				new Recorded(20, new OnCompleted())
				], Assert.fail);
		}
		
		[Test]
		public function unsubscribes_from_both_sources_on_completion() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);
				
			scheduler.runTo(15);
				
			Assert.assertEquals(15, left.subscriptions[0].unsubscribe);
			Assert.assertEquals(15, right.subscriptions[0].unsubscribe);
		}
		
		[Test]
		public function returns_false_on_value_mismatch() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(2)),
					new Recorded(20, new OnNext(2)),
					new Recorded(25, new OnCompleted())
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);
				
			scheduler.runTo(20);
				
			observer.assertTimings([
				new Recorded(10, new OnNext(false)),
				new Recorded(10, new OnCompleted())
				], Assert.fail);
		}
		
		[Test]
		public function returns_false_on_value_mismatch_using_comparer() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext({v:0})),
					new Recorded(10, new OnNext({v:1})),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext({v:0})),
					new Recorded(10, new OnNext({v:2})),
					new Recorded(20, new OnCompleted())
				]);
			
			left.sequenceEqual(right, function(l:Object,r:Object):Boolean
				{
					return l.v == r.v;
				})
				.subscribeWith(observer);

			scheduler.runTo(20);

			observer.assertTimings([
				new Recorded(10, new OnNext(false)),
				new Recorded(10, new OnCompleted())
				], Assert.fail);
		}
		
		[Test]
		public function returns_false_if_value_is_received_after_one_side_completes() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(20, new OnNext(2)),
					new Recorded(25, new OnCompleted())
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);
				
			scheduler.runTo(20);
				
			observer.assertTimings([
				new Recorded(20, new OnNext(false)),
				new Recorded(20, new OnCompleted())
				], Assert.fail);
		}
		
		[Test]
		public function errors_if_error_returned_while_both_are_active() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var error : Error = new Error();
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnError(error))
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(20, new OnNext(2)),
					new Recorded(25, new OnCompleted())
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);
				
			scheduler.runTo(20);
				
			observer.assertTimings([
				new Recorded(15, new OnError(error))
				], Assert.fail);
		}
		
		[Test]
		public function errors_if_error_returned_after_one_side_completes() : void
		{
			var scheduler : TestScheduler = new TestScheduler();
			var observer : MockObserver = new MockObserver(scheduler);
			
			var error : Error = new Error();
			
			var left : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(15, new OnCompleted())
				]);
				
			var right : ColdObservable = scheduler.createColdObservable([
					new Recorded(5, new OnNext(0)),
					new Recorded(10, new OnNext(1)),
					new Recorded(20, new OnError(error))
				]);
			
			left.sequenceEqual(right)
				.subscribeWith(observer);
				
			scheduler.runTo(20);
				
			observer.assertTimings([
				new Recorded(20, new OnError(error))
				], Assert.fail);
		}

	}
}