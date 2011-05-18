package raix.reactive.tests.operators.mutation
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.Recorded;
	import raix.reactive.testing.TestScheduler;
	
	[TestCase]
	public class ExpandFixture
	{
		[Test]
        public function recursively_expands_values_and_merges() : void
        {
            var scheduler : TestScheduler = new TestScheduler();

            var observer : MockObserver = new MockObserver(scheduler);

            scheduler.createColdObservable([
                new Recorded(5, new OnNext(0)),
                new Recorded(10, new OnNext(1)),
                new Recorded(15, new OnNext(2)),
                new Recorded(15, new OnCompleted())
            ])
            .expand(function(i:int):IObservable
            {
            	return (i < 300)
            		? scheduler.createColdObservable([
	                    new Recorded(5, new OnNext(i + 100)),
	                    new Recorded(5, new OnCompleted())])
                    : Observable.empty()
            })
            .subscribeWith(observer);

            scheduler.run();

            observer.assertTimings([
                new Recorded(5, new OnNext(0)),
                new Recorded(10, new OnNext(1)),
                new Recorded(10, new OnNext(100)),
                new Recorded(15, new OnNext(2)),
                new Recorded(15, new OnNext(101)),
                new Recorded(15, new OnNext(200)),
                new Recorded(20, new OnNext(102)),
                new Recorded(20, new OnNext(201)),
                new Recorded(20, new OnNext(300)),
                new Recorded(25, new OnNext(202)),
                new Recorded(25, new OnNext(301)),
                new Recorded(30, new OnNext(302)),
                new Recorded(30, new OnCompleted())
            ], Assert.fail);
        }

	}
}