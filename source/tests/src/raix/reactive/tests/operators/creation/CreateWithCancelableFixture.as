package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver; 
	
	public class CreateWithCancelableFixture
	{
		public function CreateWithCancelableFixture()
		{
		}
			
		[Test]
        public function create_calls_delegate() : void
        {	
            var createCalled : Boolean = false;

            Observable.createWithCancelable(function(x:IObserver) : ICancelable{ createCalled = true; return Cancelable.empty; })
                .subscribeWith(new Subject());

            Assert.assertTrue(createCalled);
        }

        [Test]
        public function calls_dispose_function_when_unsubscribed_from() : void
        {
            var disposeCalled : Boolean = false;

            var stats : StatsObserver = new StatsObserver();

            Observable.createWithCancelable(function(x:IObserver):ICancelable
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

            Observable.createWithCancelable(function(x:IObserver) : ICancelable
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
            

            Observable.createWithCancelable(function(x:IObserver) : ICancelable
            { 
                x.onError(new Error());

                return Cancelable.create(function():void { disposeCalled = true; });
            })
            .subscribeWith(stats);

            Assert.assertTrue(disposeCalled);
        }

        [Test]
        public function supports_null_cancelable_value() : void
        {
            var stats : StatsObserver = new StatsObserver();

            Observable.createWithCancelable(function(x:IObserver) : ICancelable { return null; })
                .subscribeWith(stats)
                .cancel();
        }
	}
}