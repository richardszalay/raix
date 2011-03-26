package raix.reactive.tests.operators.mutation
{
	import flash.utils.Dictionary;
	
	import org.flexunit.Assert;
	
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.AssertEx;
	import raix.reactive.tests.mocks.StatsObserver;
	
	[TestCase]
	public class GroupByUntilFixture
	{
		private var source : IObservable = Observable.fromArray([
                new GroupableObject(0, 1),
                new GroupableObject(1, 2),
                new GroupableObject(2, 3),
                new GroupableObject(0, 4),
                new GroupableObject(1, 5),
                new GroupableObject(2, 6)
            ]);
            
        [Test]
        public function groups_are_recreated_after_duration_ends() : void
        {
            var groupKeys : Array = new Array();

            source.groupByUntil(mapKey, function(g:IGroupedObservable):IObservable
	            {
	            	return Observable.empty();
	            }, mapValue)
                .subscribe(function (group : IGroupedObservable) : void
                {
                    groupKeys.push(group.key);
                });

            Assert.assertEquals(6, groupKeys.length);
        }

        [Test]
        public function group_duration_can_be_completed_by_a_value() : void
        {
			var groupKeys : Array = new Array();
			
			var subjectSource : Subject = new Subject();
			
			subjectSource.groupByUntil(mapKey, function(g:IGroupedObservable):IObservable
				{
					return Observable.value(1)
						.concat(Observable.never());
				}, mapValue)
				.subscribe(function (group : IGroupedObservable) : void
				{
					groupKeys.push(group.key);
				});
		
			subjectSource.onNext(new GroupableObject(0, 1));
			subjectSource.onNext(new GroupableObject(1, 2));
			subjectSource.onNext(new GroupableObject(2, 3));
			subjectSource.onNext(new GroupableObject(0, 4));
			subjectSource.onNext(new GroupableObject(1, 5));
			subjectSource.onNext(new GroupableObject(2, 6));
			subjectSource.onCompleted();
			
			Assert.assertEquals(6, groupKeys.length);
        }

        [Test]
        public function durations_are_unsubscribed_from_oncompleted() : void
        {
            var groupStats : StatsObserver = new StatsObserver();

            var durationSubjects : Array = new Array();

            source.groupByUntil(mapKey, function(g:IGroupedObservable):IObservable
                {
                    var duration : Subject = new Subject(); 
                    durationSubjects.push(duration); 
                    return duration;
                }, mapValue)
                .subscribeWith(groupStats);

			AssertEx.assertArrayEquals(
                [false, false, false],
                [durationSubjects[0].hasSubscriptions, durationSubjects[1].hasSubscriptions, 
                	durationSubjects[2].hasSubscriptions]);
        }

        [Test]
        public function durations_are_unsubscribed_from_onerror() : void
        {
            var groupStats : StatsObserver = new StatsObserver();

            var durationSubjects : Array = new Array();

            source.concat(Observable.error(new Error()))
            	.groupByUntil(mapKey, function(g:IGroupedObservable):IObservable
	            {
	                var duration : Subject = new Subject();
	                durationSubjects.push(duration);
	                return duration;
	            }, mapValue)
                .subscribeWith(groupStats);

            AssertEx.assertArrayEquals(
                [false, false, false],
                [durationSubjects[0].hasSubscriptions, durationSubjects[1].hasSubscriptions, 
                	durationSubjects[2].hasSubscriptions]);
        }

        [Test]
        public function groups_are_created_for_each_key() : void
        {
        	var keys : Array = new Array();
            var dictionary : Dictionary = new Dictionary();

            source.groupByUntil(mapKey, neverDuration, mapValue)
                .subscribe(function(group : IGroupedObservable) : void
                    {
                    	keys.push(group.key);
                        dictionary[group.key] = new Array();

                        group.subscribe(function(value:int) : void
                        {
                        	dictionary[group.key].push(value);
                        });
                    });

            Assert.assertEquals(3, keys.length);
            AssertEx.assertArrayEquals([ 0, 1, 2 ], keys);
            AssertEx.assertArrayEquals([ 1, 4 ], dictionary[0]);
            AssertEx.assertArrayEquals([ 2, 5 ], dictionary[1]);
            AssertEx.assertArrayEquals([ 3, 6 ], dictionary[2]);
        }

        [Test]
        public function error_thrown_by_keyselector_sent_to_onerror() : void
        {
            var stats : StatsObserver = new StatsObserver();

            source.groupByUntil(throwError, neverDuration, mapValue)
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function error_thrown_by_elementselector_sent_to_onerror() : void
        {
            var stats : StatsObserver = new StatsObserver();

            source.groupByUntil(mapKey, neverDuration, throwError)
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function error_thrown_by_keycomparer_sent_to_onerror() : void
        {
            var stats : StatsObserver = new StatsObserver();

            source.groupByUntil(mapKey, neverDuration, mapValue, throwError)
                .subscribeWith(stats);

            Assert.assertTrue(stats.errorCalled);
        }

        [Test]
        public function errors_are_emitted_into_each_group() : void
        {
            var outsideError : Boolean = false;
            var groupStats : StatsObserver = new StatsObserver();

            Observable.value(1).concat(Observable.error(new Error()))
                .groupByUntil(mapSelf, neverDuration)
                .subscribe(
                	function(group : IGroupedObservable) : void
                    {
                        group.subscribeWith(groupStats);
                    }, 
                    null,
                    function(e:Error):void
					{
						outsideError = true;
					});

            Assert.assertTrue(outsideError);
            Assert.assertTrue(groupStats.errorCalled);
        }
 
        private function mapKey(value : GroupableObject) : int
        {
        	return value.key;
        }
        
        private function mapValue(value : GroupableObject) : int
        {
        	return value.value;
        }
        
        private function mapSelf(value : Object) : Object
        {
        	return value;
        }
        
        private function throwError(... args) : int
        {
        	throw new Error("test");
        }
        
        private function neverDuration(g : IGroupedObservable) : IObservable
        {
        	return Observable.never();
        }

        
	}
}

class GroupableObject
{
	public function GroupableObject(key : int, value : int)
	{
		this.key = key;
		this.value = value;
	}
	
    public var key : int;

    public var value : int;
}