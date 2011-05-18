package raix.reactive.tests.operators.combine
{
	import raix.reactive.Subject;
	
	import org.flexunit.Assert;
	
	// Implementation of Erik Meijer's join sample from the Rx forums:
	// http://social.msdn.microsoft.com/Forums/en-US/rx/thread/3ca3a0d4-ac61-4325-9fa2-ed622830b518/#d0d84a8c-2e23-4175-923b-37aa066d15a4
	public class PatternJoinCounterFixture
	{
		[Test]
		public function counter_works() : void 
		{
			var counter : Counter = new Counter(0);
			
			Assert.assertEquals(0, counter.getValue());
			counter.incValue();
			Assert.assertEquals(1, counter.getValue());
		}
	}
}
	import raix.reactive.subjects.AsyncSubject;
	import raix.reactive.Subject;
	import raix.reactive.ICancelable;
	import raix.reactive.Observable;
	import raix.reactive.ISubject;
	import org.flexunit.Assert;
	

class Counter
{
	private var _inc : Subject = new Subject();
    private var _get : Subject = new Subject();
    private var _counter : Subject = new Subject();
    private var _dispose : ICancelable;
    
    public function incValue() : void
    {
    	var result : AsyncSubject = new AsyncSubject();
    	
    	_inc.onNext(result);
    }
    
    public function getValue() : int
    {
    	var result : AsyncSubject = new AsyncSubject();
    	
    	_get.onNext(result);
    	
    	return int(result.lastValue());
    }
    
    public function Counter(init:int)
    {
    	_dispose = Observable.when([
    		_counter.and(_get).then(function(n:int, result:ISubject):void 
    		{
    			_counter.onNext(n);
    			
    			result.onNext(n);
    		}),
    		_counter.and(_inc).then(function(n:int, result:ISubject):void 
    		{
    			_counter.onNext(n + 1);
    			
    			result.onNext(n);
    		})]).subscribe(null);
    		
    	_counter.onNext(init);
    }
}