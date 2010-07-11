package rx.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import rx.Cancelable;
	import rx.ICancelable;
	import rx.IObserver;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver; 
	
	public class CreateWithCancelableFixture
	{
		public function CreateWithCancelableFixture()
		{
		}
			
		[Test]
        public function create_calls_delegate() : void
        {	
            var createCalled : Boolean = false;

            Observable.createWithCancelable(int, function(x:IObserver) : ICancelable{ createCalled = true; return Cancelable.empty; })
                .subscribeWith(new Subject(int));

            Assert.assertTrue(createCalled);
        }

        [Test]
        public function calls_dispose_function_when_unsubscribed_from() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.createWithCancelable(int, function(x:IObserver):ICancelable
            	{
            		return Cancelable.create(function():void
            		{
            			disposeCalled = true;
            		});
            	})
                .subscribeWith(stats)
                .cancel();

            Assert.assertTrue(disposeCalled);
        }

        [Test]
        public function calls_dispose_function_when_sequence_completes() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.createWithCancelable(int, function(x:IObserver) : ICancelable
            { 
                x.onCompleted();

                return Cancelable.create(function():void { disposeCalled = true; });
            })
            .subscribeWith(stats);

            Assert.assertTrue(disposeCalled);
        }

        [Test]
        public function calls_dispose_function_when_sequence_errors() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();
            

            Observable.createWithCancelable(int, function(x:IObserver) : ICancelable
            { 
                x.onError(new Error());

                return Cancelable.create(function():void { disposeCalled = true; });
            })
            .subscribeWith(stats);

            Assert.assertTrue(disposeCalled);
        }

        [Test(expects=ArgumentError)]
        public function throws_argument_error_when_return_value_is_null() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.createWithCancelable(int, function(x:IObserver) : ICancelable { return null; })
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }
	}
}