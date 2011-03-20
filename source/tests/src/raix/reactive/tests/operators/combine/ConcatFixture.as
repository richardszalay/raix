package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.*;
	import raix.reactive.tests.mocks.ManualScheduler;
	import raix.reactive.tests.mocks.StatsObserver;
	
	public class ConcatFixture
	{
		[Test]
        public function runs_each_sequence_and_completes() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
        	Observable.concat([
        		Observable.returnValue(1),
        		Observable.returnValue(2),
        		Observable.returnValue(3)
        		])
        		.subscribeWith(stats);
            
            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(2, stats.nextValues[1]);
            Assert.assertEquals(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
        }
        
        [Test]
        public function can_be_cancelled_at_any_time() : void
        {
            var stats : StatsObserver = new StatsObserver();
            
            var subjectA : Subject = new Subject();
            var subjectB : Subject = new Subject();
            var subjectC : Subject = new Subject();
            
        	var subs : ICancelable = Observable.concat([
        		subjectA,
        		subjectB,
        		subjectC
        		])
        		.subscribeWith(stats);
        		
        	subs.cancel();
            
            Assert.assertFalse(subjectA.hasSubscriptions);
            Assert.assertFalse(subjectB.hasSubscriptions);
            Assert.assertFalse(subjectC.hasSubscriptions);
            Assert.assertFalse(stats.completedCalled);
        }        
       
        [Test]
        public function can_resubscribe() : void
        {
        	var obs : IObservable = Observable.returnValue(1)
        		.concat([Observable.returnValue(2)]);
        		
        	var statsA : StatsObserver = new StatsObserver();
        	var statsB : StatsObserver = new StatsObserver();
        	
        	obs.subscribeWith(statsA);
        	obs.subscribeWith(statsB);
        	
        	Assert.assertEquals(2, statsB.nextCount); 
        	Assert.assertEquals(1, statsB.nextValues[0]); 
        	Assert.assertEquals(2, statsB.nextValues[1]); 
        	Assert.assertTrue(statsB.completedCalled); 
        }
	}
}