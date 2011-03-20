package raix.reactive.tests.operators.creation
{
	import flash.utils.Dictionary;
	
	import org.flexunit.Assert;
	
	import raix.reactive.Observable;
	import raix.reactive.tests.mocks.StatsObserver; 
	
	public class LookupFixture
	{
		[Test]
        public function lookup_value_is_subscribed_to() : void
        {
            var dictionary : Dictionary = new Dictionary();
            dictionary["keyA"] = Observable.returnValue(1);
            dictionary["keyB"] = Observable.returnValue(2);
            dictionary["keyC"] = Observable.returnValue(3);

            var stats : StatsObserver = new StatsObserver();

            Observable.lookup(function():String { return "keyB"; }, dictionary)
                .subscribeWith(stats);

            Assert.assertEquals(1, stats.nextCount);
            Assert.assertEquals(2, stats.nextValues[0]);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function empty_is_returned_if_lookup_key_is_invalid() : void
        {
            var dictionary : Dictionary = new Dictionary();
            dictionary["keyA"] = Observable.returnValue(1);
            dictionary["keyB"] = Observable.returnValue(2);
            dictionary["keyC"] = Observable.returnValue(3);

            var stats : StatsObserver = new StatsObserver();

            Observable.lookup(function():String { return "keyD"; }, dictionary)
                .subscribeWith(stats);

            Assert.assertFalse(stats.nextCalled);
            Assert.assertTrue(stats.completedCalled);
        }

        [Test]
        public function error_is_raised_if_selector_throws_exception() : void
        {
            var dictionary : Dictionary = new Dictionary();
            dictionary["keyA"] = Observable.returnValue(1);
            dictionary["keyB"] = Observable.returnValue(2);
            dictionary["keyC"] = Observable.returnValue(3);

            var stats : StatsObserver = new StatsObserver();

            var exception : Error = new ArgumentError();

            Observable.lookup(function():String { throw exception; }, dictionary)
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
            Assert.assertEquals(exception, stats.error);
            
        }
	}
}