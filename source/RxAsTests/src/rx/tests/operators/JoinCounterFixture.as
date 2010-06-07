package rx.tests.operators
{
	import rx.Subject;
	
	import org.flexunit.Assert;
	
	// Implementation of Erik Meijer's join sample from the Rx forums:
	// http://social.msdn.microsoft.com/Forums/en-US/rx/thread/3ca3a0d4-ac61-4325-9fa2-ed622830b518/#d0d84a8c-2e23-4175-923b-37aa066d15a4
	public class JoinCounterFixture
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
	import rx.subjects.AsyncSubject;
	import rx.Subject;
	import rx.ICancelable;
	import rx.Observable;
	import rx.ISubject;
	import org.flexunit.Assert;
	

class Counter
{
	private var _inc : Subject = new Subject(ISubject);
    private var _get : Subject = new Subject(ISubject);
    private var _counter : Subject = new Subject(int);
    private var _dispose : ICancelable;
    
    public function incValue() : void
    {
    	var result : AsyncSubject = new AsyncSubject(int);
    	
    	_inc.onNext(result);
    }
    
    public function getValue() : int
    {
    	var result : AsyncSubject = new AsyncSubject(int);
    	
    	_get.onNext(result);
    	
    	return int(result.lastValue());
    }
    
    public function Counter(init:int)
    {
    	_dispose = Observable.join(int, [
    		_counter.and(_get).then(int, function(n:int, result:ISubject):void 
    		{
    			_counter.onNext(n);
    			
    			result.onNext(n);
    		}),
    		_counter.and(_inc).then(int, function(n:int, result:ISubject):void 
    		{
    			_counter.onNext(n + 1);
    			
    			result.onNext(n);
    		})]).subscribeFunc(null);
    		
    	_counter.onNext(init);
    }
}