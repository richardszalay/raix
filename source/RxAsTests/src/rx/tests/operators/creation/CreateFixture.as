package rx.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import rx.Cancelable;
	import rx.ICancelable;
	import rx.IObserver;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver; 
	
	public class CreateFixture
	{
		[Test]
        public function create_calls_delegate() : void
        {
            var createCalled : Boolean = false;

            Observable.create(int, function(x:IObserver):Function { createCalled = true; return function():void { }; })
                .subscribeWith(new Subject(int));

            Assert.assertTrue(createCalled);
        }

        [Test]
        public function calls_dispose_function_when_unsubscribed_from() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.create(int, function(x:IObserver):Function { return function():void { disposeCalled = true; } })
                .subscribeWith(stats)
                .cancel();

            Assert.assertTrue(disposeCalled);
        }

        [Test]
        public function calls_dispose_function_when_sequence_completes() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.create(int, function(x:IObserver):Function { x.onCompleted(); return function():void { disposeCalled = true; }; })
                .subscribeWith(stats);

            Assert.assertTrue(disposeCalled);
        }

        [Test]
        public function calls_dispose_function_when_sequence_errors() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.create(int, function(x:IObserver):Function { x.onError(new Error()); return function():void { disposeCalled = true; }; })
                .subscribeWith(stats);

            Assert.assertTrue(disposeCalled);
        }

        /* [Test(expects=ArgumentError)]
        public function throws_argument_error_when_return_value_is_null() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.create(int, function(x:IObserver):Function { return null; })
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        } */
	}
}